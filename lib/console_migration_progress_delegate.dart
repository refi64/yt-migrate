import 'dart:io';
import 'dart:math';

import 'package:cli_util/cli_logging.dart' hide Logger;

import 'account_state.dart';
import 'logger.dart';
import 'migrate.dart';

class _ProgressBar {
  String description;
  final Ansi ansi;

  _ProgressBar(this.description, this.ansi);

  Future<void> update(double progress) async {
    var begin = ' $description [';
    var end = '] ${(progress * 100).truncate().toString().padLeft(3)}%';
    var progressColumns = stdout.terminalColumns - (begin.length + end.length);
    var arrowColumns = 1;
    var filledColumns =
        max((progressColumns * progress).truncate() - arrowColumns, 0);

    stdout.write('\r');
    stdout.write(ansi.emphasized(begin));
    stdout.write('=' * filledColumns);
    stdout.write('>');
    stdout.write(' ' * (progressColumns - filledColumns - arrowColumns));
    stdout.write(ansi.emphasized(end));

    await stdout.flush();
  }

  Future<void> finish({bool completed = true}) async {
    if (completed) {
      await update(1);
    }

    stdout.writeln();
  }
}

class ConsoleMigrationProgressDelegate implements MigrationProgressDelegate {
  Ansi ansi;
  _ProgressBar _progressBar;

  ConsoleMigrationProgressDelegate() : ansi = Logger.instance.ansi;

  @override
  Future<void> beginStage(AccountResourceType type, int total) async {
    String description;
    switch (type) {
      case AccountResourceType.like:
        description = 'Likes';
        break;
      case AccountResourceType.subscription:
        description = 'Subscriptions';
        break;
    }

    _progressBar = _ProgressBar(description, ansi);
    await _progressBar.update(0);
  }

  @override
  Future<void> updateStage(
          AccountResourceType type, int completed, int total) async =>
      await _progressBar.update(completed.toDouble() / total.toDouble());

  @override
  Future<void> interruptStage(AccountResourceType type) async {
    _progressBar.description = ansi.error('ERROR');
    await _progressBar.finish(completed: false);
  }

  @override
  Future<void> finishStage(AccountResourceType type) async {
    await _progressBar.finish();
  }
}
