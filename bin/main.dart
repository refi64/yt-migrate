import 'dart:io';

import 'package:args/args.dart';
import 'package:yt_migrate/driver.dart';
import 'package:yt_migrate/finalizer_pool.dart';
import 'package:yt_migrate/logger.dart';

File maybeFile(String path) => path != null ? File(path) : null;

Future<void> main(List<String> arguments) async {
  var parser = ArgParser();
  parser.addOption('client-id-file',
      abbr: 'c', help: 'Path to client_id.json (required)');
  parser.addOption('takeout-zip',
      abbr: 't', help: 'Your takeout-*.zip (required)');
  parser.addOption('credentials-cache-file',
      abbr: 'C', help: 'Path to a file to cache credentials in');
  parser.addFlag('verbose', abbr: 'v', help: 'Enable verbose logging');
  parser.addFlag('keep-going', abbr: 'k', help: 'Keep going on errors');
  parser.addFlag('help', abbr: 'h', help: 'Show this screen');

  var results;
  try {
    results = parser.parse(arguments);
  } on ArgParserException catch (ex) {
    Logger.instance.error(ex.message);
    exit(1);
  }

  if (results['help']) {
    print('usage: yt-migrate [<flags...>]');
    print(parser.usage);
    exit(0);
  }

  if (results['verbose']) {
    Logger.makeVerbose();
  }

  if (results['client-id-file'] == null ||
      results['credentials-cache-file'] == null) {
    Logger.instance.error(
        'Both --client-id-file and --credentials-cache-file must be given.');
    exit(1);
  }

  await FinalizerPool.instance.runAsync(() async {
    await runAppInFinalizerPool(
        clientIdFile: File(results['client-id-file']),
        credentialsFile: maybeFile(results['credentials-cache-file']),
        takeoutFile: File(results['takeout-zip']),
        keepGoing: results['keep-going']);
  });

  exit(0);
}
