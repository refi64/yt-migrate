import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:googleapis/youtube/v3.dart';
import 'package:path/path.dart' as p;

import 'account_state.dart';
import 'collection_utils.dart';
import 'logger.dart';
import 'resource.dart';

class Takeout {
  Takeout();

  AccountState _state;
  AccountState get state => _state;

  List _loadArchivedJson(ArchiveFile file) =>
      jsonDecode(utf8.decode(file.content));

  Set<VideoById> _loadLikes(ArchiveFile file) =>
      Set.from(_loadArchivedJson(file).mapWithIndex((index, item) =>
          VideoById.playlistItem(PlaylistItem.fromJson(item), index)));

  Set<ChannelById> _loadSubscriptions(ArchiveFile file) =>
      Set.from(_loadArchivedJson(file).mapWithIndex((index, item) =>
          ChannelById.subscribed(Subscription.fromJson(item), index)));

  void loadStateFromArchive(Archive archive) {
    var likes = <VideoById>{};
    var subscriptions = <ChannelById>{};

    for (var file in archive) {
      var parts = p.split(file.name);
      if (parts.length > 2 &&
          parts[0] == 'Takeout' &&
          parts[1] == 'YouTube and YouTube Music') {
        var name = parts.last;

        if (name == 'likes.json') {
          likes = _loadLikes(file);
        } else if (name == 'subscriptions.json') {
          subscriptions = _loadSubscriptions(file);
        }
      }
    }

    var privateLikes = likes.where((v) => v.private).toSet();
    if (privateLikes.isNotEmpty) {
      var logger = Logger.instance;
      logger.warning(
          'The following likes are now private and will not be migrated:');
      for (var video in privateLikes) {
        logger.warningItem(video.id);
      }
    }
    likes.removeAll(privateLikes);

    _state = AccountState(likes, subscriptions);
  }

  Future<void> loadStateFromZipFile(File file) async => loadStateFromArchive(
      ZipDecoder().decodeBytes(await file.readAsBytesSync()));
}
