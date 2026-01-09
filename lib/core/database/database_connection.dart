import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_logging_service/flutter_logging_service.dart';

/// Opens a database connection using drift_flutter for mobile platforms only
/// This app is designed for Android/iOS only
QueryExecutor openConnection() {
  Log.info('Opening database connection with drift_flutter (mobile only)');

  // drift_flutter handles platform-specific setup automatically:
  // - Android/iOS: Uses sqlite3_flutter_libs
  return driftDatabase(name: 'mizaniyah');
}
