import 'package:counters/common/db/db_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

@riverpod
DatabaseHelper database(Ref ref) {
  return DatabaseHelper.instance;
}
