import 'package:googleapis/youtube/v3.dart';

import 'account_state.dart';
import 'collection_utils.dart';
import 'resource.dart';

Future<void> _iteratePages(Future<String> Function(String) processPage) async {
  String pageToken;

  do {
    pageToken = await processPage(pageToken);
  } while (pageToken != null);
}

class TargetAccount {
  final YoutubeApi _yt;
  Channel _channel;
  AccountState _state;

  Channel get channel => _channel;
  AccountState get state => _state;

  TargetAccount(this._yt);

  Future<void> loadState() async {
    var channels = await _yt.channels.list('id', mine: true);
    if (channels.items.length != 1) {
      throw Exception('Bad # of channels');
    }

    var likes = <VideoById>{};
    var subscriptions = <ChannelById>{};

    await _iteratePages((pageToken) async {
      var response =
          await _yt.videos.list('id', pageToken: pageToken, myRating: 'like');
      likes.addAll(response.items
          .mapWithIndex((index, item) => VideoById.id(item.id, index: index)));

      return response.nextPageToken;
    });

    await _iteratePages((pageToken) async {
      var response = await _yt.subscriptions
          .list('snippet', pageToken: pageToken, mine: true);
      subscriptions.addAll(response.items
          .mapWithIndex((index, item) => ChannelById.subscribed(item, index)));

      return response.nextPageToken;
    });

    _channel = channels.items.first;
    _state = AccountState(likes, subscriptions);
  }

  Future<void> likeVideo(VideoById video) async {
    await _yt.videos.rate(video.id, 'like');
  }

  Future<void> subscribeToChannel(ChannelById channel) async {
    await _yt.subscriptions.insert(
        Subscription()
          ..snippet = (SubscriptionSnippet()
            ..resourceId = (ResourceId()
              ..kind = 'youtube#channel'
              ..channelId = channel.id)),
        'snippet');
  }
}
