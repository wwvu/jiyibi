class AppLogger {
  const AppLogger._();

  static void d(String tag, String message) {
    // MVP placeholder. S1 will enable debug-only logging with redaction rules.
  }

  static void record(String action, int id) {
    d('Record', '$action id=$id');
  }
}
