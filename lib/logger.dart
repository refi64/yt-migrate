import 'package:cli_util/cli_logging.dart' as cli_logging;

class Logger {
  static Logger _instance = Logger._(cli_logging.Logger.standard());
  static Logger get instance => _instance;

  final cli_logging.Logger _logger;
  int _indentationLevel = 0;

  cli_logging.Ansi get ansi => _logger.ansi;

  Logger._(this._logger);

  static void makeVerbose() {
    _instance = Logger._(cli_logging.Logger.verbose());
  }

  void withIndent(void Function() func) {
    _indentationLevel += 1;
    try {
      func();
    } finally {
      _indentationLevel -= 1;
    }
  }

  String _indented(String s) => (' ' * (_indentationLevel * 2)) + s;

  void plain(String message) => _logger.stdout(_indented(message));
  void info(String message) => plain(ansi.emphasized(message));
  void header(String message) => info(ansi.blue + message + ansi.none);
  void item(String item) => plain('${ansi.subtle('-')} ${item}');
  void warningItem(String item) => this.item(ansi.magenta + item + ansi.none);
  void debug(String message) => _logger.trace(_indented(ansi.subtle(message)));
  void warning(String message) => _logger
      .stderr(ansi.emphasized(_indented(ansi.magenta + message + ansi.none)));
  void error(String message) =>
      _logger.stderr(ansi.emphasized(_indented(ansi.error(message))));
}
