import 'dart:io';

import 'package:googleapis/youtube/v3.dart';

import 'account_state.dart';
import 'auth.dart';
import 'collection_utils.dart';
import 'console_migration_progress_delegate.dart';
import 'finalizer_pool.dart';
import 'logger.dart';
import 'migrate.dart';
import 'target_account.dart';
import 'takeout.dart';

Future<void> runAppInFinalizerPool(
    {File clientIdFile,
    File credentialsFile,
    File takeoutFile,
    bool keepGoing}) async {
  var logger = Logger.instance;

  logger.info('Authorizing with YouTube...');

  var clientId = await ClientIdSerialization.fromInstalled(clientIdFile);
  var client = credentialsFile != null && await credentialsFile.exists()
      ? await authorizeClientFromSavedCredentials(clientId, credentialsFile)
      : await authorizeNewClient(
          clientId, (url) => print('Authorize yt-mgirate at ${url}'));
  FinalizerPool.instance.register(CloseFinalizer(client));

  if (credentialsFile != null) {
    await client.credentials.saveToFile(credentialsFile);
  }

  var yt = YoutubeApi(client);

  logger.info('Retrieving current target user information...');
  var target = TargetAccount(yt);
  await target.loadState();

  logger.info('Loading takeout file...');
  var takeout = Takeout();
  await takeout.loadStateFromZipFile(takeoutFile);

  var additionalState = takeout.state.without(target.state);
  if (additionalState.likes.isEmpty && additionalState.subscriptions.isEmpty) {
    logger.info('Account is already migrated.');
  } else {
    logger.info('Going to migrate the following data:');

    logger.withIndent(() {
      var resourceTypeNames = {
        AccountResourceType.like: 'liked video(s)',
        AccountResourceType.subscription: 'subscription(s)'
      };

      for (var type in resourceTypeNames.keys) {
        var resources = additionalState.resources(type);
        if (resources.isEmpty) {
          continue;
        }

        logger.header('${resources.length} ${resourceTypeNames[type]}:');
        logger.withIndent(() => resources
            .sortedBy((r) => r.title.toLowerCase())
            .map((r) => r.title)
            .forEach(logger.item));
      }
    });
  }

  for (;;) {
    stdout.write('Confirm? (y/n) ');
    var input = stdin.readLineSync().toLowerCase();
    if (input == 'y') {
      break;
    } else if (input == 'n') {
      return;
    }
  }

  var migrator =
      Migrator(target, ConsoleMigrationProgressDelegate(), keepGoing);
  await migrator.run(additionalState);

  // Save any refreshed credentials again.
  if (credentialsFile != null) {
    await client.credentials.saveToFile(credentialsFile);
  }
}
