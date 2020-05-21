import 'resource.dart';

enum AccountResourceType { like, subscription }

class AccountState {
  final Set<VideoById> likes;
  final Set<ChannelById> subscriptions;

  AccountState(this.likes, this.subscriptions);

  Set<ResourceById> resources(AccountResourceType type) {
    switch (type) {
      case AccountResourceType.like:
        return likes;
      case AccountResourceType.subscription:
        return subscriptions;
    }

    throw ArgumentError('Invalid resource type: $type');
  }

  AccountState without(AccountState other) => AccountState(
      likes.difference(other.likes),
      subscriptions.difference(other.subscriptions));
}
