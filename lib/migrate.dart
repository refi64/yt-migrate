import 'package:googleapis/youtube/v3.dart';

import 'account_state.dart';
import 'collection_utils.dart';
import 'logger.dart';
import 'resource.dart';
import 'target_account.dart';

abstract class MigrationProgressDelegate {
  Future<void> beginStage(AccountResourceType type, int total);
  Future<void> updateStage(AccountResourceType type, int completed, int total);
  Future<void> interruptStage(AccountResourceType type);
  Future<void> finishStage(AccountResourceType type);
}

class Migrator {
  final TargetAccount target;
  final MigrationProgressDelegate _progressDelegate;
  final bool keepGoing;

  Migrator(this.target, this._progressDelegate, this.keepGoing);

  Future<void> _migrateResources(
      AccountResourceType type, List<ResourceById> sortedResources) async {
    for (var i = 0; i < sortedResources.length; i++) {
      var resource = sortedResources[i];

      if (resource.index == -1) {
        throw ArgumentError('Resource has no index: ${resource.title}');
      }

      try {
        switch (type) {
          case AccountResourceType.like:
            await target.likeVideo(resource as VideoById);
            break;
          case AccountResourceType.subscription:
            await target.subscribeToChannel(resource as ChannelById);
            break;
        }
      } catch (ex) {
        var message = 'Failed to migrate ${resource.id} (${resource.title}):'
            '\n  ${ex.message}';
        if (keepGoing && ex is ApiRequestError) {
          Logger.instance.warning(message);
        } else {
          Logger.instance.error(message);
          rethrow;
        }
      }

      await _progressDelegate.updateStage(type, i + 1, sortedResources.length);
    }
  }

  Future<void> run(AccountState additionalState) async {
    for (var type in AccountResourceType.values) {
      var resources = additionalState.resources(type);
      if (resources.isEmpty) {
        continue;
      }

      var sortedResources =
          resources.sortedBy((r) => resources.length - r.index);
      await _progressDelegate.beginStage(type, sortedResources.length);

      try {
        await _migrateResources(type, sortedResources);
      } catch (_) {
        await _progressDelegate.interruptStage(type);
        rethrow;
      }

      await _progressDelegate.finishStage(type);
    }
  }
}
