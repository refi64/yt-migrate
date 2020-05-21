import 'package:googleapis/youtube/v3.dart';

abstract class ResourceById {
  int get index;
  String get id;
  String get title;

  ResourceById withIndex(int index);
}

abstract class ResourceByIdImpl<V> implements ResourceById {
  @override
  bool operator ==(dynamic other) =>
      other is ResourceByIdImpl<V> && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class VideoById extends ResourceByIdImpl<Video> {
  @override
  final int index;
  final bool private;
  final Video video;

  VideoById(this.video, {this.index = -1, this.private = false});
  factory VideoById.id(String id, {int index = -1, bool private = false}) =>
      VideoById(Video()..id = id, index: index, private: private);
  factory VideoById.playlistItem(PlaylistItem item, [int index = -1]) =>
      VideoById(
          Video()
            ..id = item.snippet.resourceId.videoId
            ..snippet = (VideoSnippet()..title = item.snippet.title),
          index: index,
          private: item.status.privacyStatus == 'private');

  @override
  String get id => video.id;
  @override
  String get title => video.snippet?.title;

  @override
  ResourceById withIndex(int newIndex) =>
      VideoById(video, index: newIndex, private: private);
}

class ChannelById extends ResourceByIdImpl<Channel> {
  @override
  final int index;
  final Channel channel;

  ChannelById(this.channel, [this.index = -1]);
  factory ChannelById.id(String id, [int index = -1]) =>
      ChannelById(Channel()..id = id, index);
  factory ChannelById.subscribed(Subscription subscription, [int index = -1]) =>
      ChannelById(
          Channel()
            ..id = subscription.snippet.resourceId.channelId
            ..snippet = (ChannelSnippet()..title = subscription.snippet.title),
          index);

  @override
  String get id => channel.id;
  @override
  String get title => channel.snippet?.title;

  @override
  ResourceById withIndex(int newIndex) => ChannelById(channel, newIndex);
}
