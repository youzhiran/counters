import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../db/db_helper.dart';

part 'database_provider.g.dart';

@riverpod
DatabaseHelper database(Ref ref) {
  return DatabaseHelper.instance;
}
