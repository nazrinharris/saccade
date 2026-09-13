import 'package:fpdart/fpdart.dart';

import 'teable_decoders.dart';
import 'teable_field.dart';
import 'teable_http.dart';
import 'teable_record.dart';

/// Teable-aware layer. Knows the base, the API paths, and the query
/// params Teable requires. Sits above the swappable transport.
class TeableClient {
  final TeableHttpClient _http;
  final String baseId;

  TeableClient({required this._http, required this.baseId});

  /// Every Teable request must carry fieldKeyType=name: cell keys are
  /// field names, and if this ever defaults to ID mode every mapper
  /// returns empty with no error. Appended here so it cannot be omitted.
  Map<String, String> _query([Map<String, String>? extra]) => {
    'fieldKeyType': 'name',
    ...?extra,
  };

  /// 200 means the PAT is good.
  Future<Either<TeableRequestFailure, Unit>> checkAuth() async {
    final result = await _http.get('/api/auth/user', query: _query());
    return result.map((_) => unit);
  }

  Future<Either<TeableRequestFailure, List<TeableField>>> listFields(
    String tableId,
  ) async {
    final result = await _http.get(
      '/api/table/$tableId/field',
      query: _query(),
    );
    return result.flatMap((json) {
      try {
        final list = json as List;
        return Right([
          for (final f in list) decodeField(f as Map<String, dynamic>),
        ]);
      } on Exception catch (e) {
        return Left(MalformedResponseFailure('Bad field list: $e'));
      }
    });
  }

  Future<Either<TeableRequestFailure, List<TeableTable>>> listTables() async {
    final result = await _http.get('/api/base/$baseId/table', query: _query());
    return result.flatMap((json) {
      try {
        final list = json as List;
        return Right([
          for (final t in list)
            TeableTable(
              id: (t as Map)['id'] as String,
              name: t['name'] as String,
            ),
        ]);
      } on Exception catch (e) {
        return Left(MalformedResponseFailure('Bad table list: $e'));
      }
    });
  }

  Future<Either<TeableRequestFailure, List<TeableRecordDto>>> pageRecords(
    String tableId, {
    required int take,
    required int skip,
  }) async {
    final result = await _http.get(
      '/api/table/$tableId/record',
      query: _query({'take': '$take', 'skip': '$skip'}),
    );
    return result.flatMap((json) {
      try {
        final records = (json as Map)['records'] as List;
        return Right([
          for (final r in records)
            TeableRecordDto(
              id: (r as Map)['id'] as String,
              fields: r['fields'] as Map<String, dynamic>,
            ),
        ]);
      } on Exception catch (e) {
        return Left(MalformedResponseFailure('Bad record page: $e'));
      }
    });
  }

  Future<Either<TeableRequestFailure, List<TeableRecordDto>>> allRecords(
    String tableId, {
    int pageSize = 1000,
  }) async {
    final out = <TeableRecordDto>[];
    var skip = 0;
    while (true) {
      final page = await pageRecords(tableId, take: pageSize, skip: skip);
      if (page case Left(value: final failure)) return Left(failure);
      final batch = page.getRight().toNullable()!;
      out.addAll(batch);
      if (batch.length < pageSize) return Right(out);
      skip += pageSize;
    }
  }
}

class TeableTable {
  final String id;
  final String name;
  const TeableTable({required this.id, required this.name});
}
