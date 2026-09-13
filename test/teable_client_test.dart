import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:saccade/data/teable/teable_client.dart';
import 'package:saccade/data/teable/teable_decoders.dart';
import 'package:saccade/data/teable/teable_field.dart';
import 'package:saccade/data/teable/teable_field_value.dart';
import 'package:saccade/data/teable/teable_http.dart';

/// Read a captured fixture. Real Teable responses, sanitized, 2026-09-13.
String _fixture(String name) => File('test/fixtures/$name').readAsStringSync();

/// A fake transport that records every request and replies with a canned
/// body. The REAL TeableClient runs above it, so what's under test is the
/// client's request construction, not the fake's.
class _RecordingTransport implements TeableHttpClient {
  final List<Uri> requests = [];
  final String Function(Uri uri) respond;

  _RecordingTransport(this.respond);

  @override
  Future<Either<TeableRequestFailure, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('http://test.local')
        .replace(path: path, queryParameters: query);
    requests.add(uri);
    try {
      return Right(jsonDecode(respond(uri)));
    } on Exception catch (e) {
      return Left(MalformedResponseFailure('$e'));
    }
  }
}

/// A transport that always fails with a given status.
class _FailingTransport implements TeableHttpClient {
  final int status;
  _FailingTransport(this.status);

  @override
  Future<Either<TeableRequestFailure, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async => Left(UnauthorizedFailure('HTTP $status'));
}

TeableClient _client(TeableHttpClient transport) =>
    TeableClient(http: transport, baseId: 'bseMJH59ND24XhTstN0');

void main() {
  group('request construction', () {
    test('every request carries fieldKeyType=name', () async {
      final t = _RecordingTransport((uri) {
        if (uri.path.contains('/field')) return _fixture('fields-task.json');
        return _fixture('tables.json');
      });
      final client = _client(t);

      await client.listTables();
      await client.listFields('tblfTkOieln1CwH5Lkr');

      expect(t.requests, hasLength(2));
      for (final uri in t.requests) {
        expect(
          uri.queryParameters['fieldKeyType'],
          'name',
          reason: 'fieldKeyType=name must be on $uri',
        );
      }
    });

    test('record paging sends take and skip', () async {
      final t = _RecordingTransport((_) => _fixture('records-task.json'));

      await _client(t).pageRecords('tblfTkOieln1CwH5Lkr', take: 50, skip: 100);

      final uri = t.requests.single;
      expect(uri.queryParameters['take'], '50');
      expect(uri.queryParameters['skip'], '100');
      expect(uri.queryParameters['fieldKeyType'], 'name');
    });

    test('401 maps to UnauthorizedFailure', () async {
      final client = _client(_FailingTransport(401));

      final result = await client.checkAuth();

      result.fold(
        (f) => expect(f, isA<UnauthorizedFailure>()),
        (_) => fail('expected a failure'),
      );
    });
  });

  group('paging termination', () {
    /// Serves `all` in take/skip slices, exactly like Teable does.
    _RecordingTransport slicing(List<Map<String, dynamic>> all) =>
        _RecordingTransport((uri) {
          final skip = int.parse(uri.queryParameters['skip']!);
          final take = int.parse(uri.queryParameters['take']!);
          return jsonEncode({'records': all.skip(skip).take(take).toList()});
        });

    test('allRecords stops on a short page', () async {
      // Fixture has 50 records. Page size 20 -> 20, 20, 10(short) -> stop.
      final all =
          (jsonDecode(_fixture('records-task.json')) as Map)['records'] as List;
      final t = slicing([for (final r in all) r as Map<String, dynamic>]);

      final result = await _client(t)
          .allRecords('tblfTkOieln1CwH5Lkr', pageSize: 20);

      expect(result.getRight().toNullable()!, hasLength(50));
      expect(t.requests, hasLength(3));
      expect(t.requests.last.queryParameters['skip'], '40');
      expect(t.requests.last.queryParameters['fieldKeyType'], 'name');
    });

    test(
      'a full final page still terminates via the short-page rule',
      () async {
        final all =
            (jsonDecode(_fixture('records-task.json')) as Map)['records']
                as List;
        final t = slicing([for (final r in all) r as Map<String, dynamic>]);

        final result = await _client(t)
            .allRecords('tblfTkOieln1CwH5Lkr', pageSize: 50);

        expect(result.getRight().toNullable()!, hasLength(50));
        expect(
          t.requests,
          hasLength(2),
          reason: 'one full page, then an empty one to confirm the end',
        );
      },
    );

    test('pages a 1,446-record table to completion', () async {
      final all = [
        for (var i = 0; i < 1446; i++)
          {
            'id': 'rec$i',
            'fields': <String, dynamic>{'Name': 'r$i'},
          },
      ];
      final t = slicing(all);

      final result = await _client(t).allRecords('tblX', pageSize: 500);

      expect(result.getRight().toNullable()!, hasLength(1446));
      expect(
        t.requests,
        hasLength(3),
        reason: '500 + 500 + 446 (short) then stops; no fourth page needed',
      );
    });
  });

  group('field decoding', () {
    test('decodes the live field definitions', () async {
      final t = _RecordingTransport((_) => _fixture('fields-task.json'));

      final result = await _client(t).listFields('tblfTkOieln1CwH5Lkr');

      final fields = result.getRight().toNullable()!;
      expect(fields, isNotEmpty);

      final state = fields.firstWhere((f) => f.name == 'State');
      expect(state.type, 'singleSelect');
      expect(state.options, isA<SelectFieldOptions>());
      expect(
        (state.options as SelectFieldOptions).choices.map((c) => c.name),
        contains('Done'),
      );

      final project = fields.firstWhere((f) => f.name == 'Project');
      expect(project.options, isA<LinkFieldOptions>());
      expect(
        (project.options as LinkFieldOptions).relationship,
        Relationship.manyOne,
      );
    });

    test('an unknown kind throws', () {
      expect(
        () => decodeField(<String, dynamic>{
          'id': 'fldX',
          'name': 'Mystery',
          'type': 'quantumFlux',
          'options': <String, dynamic>{},
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('a known but unsupported kind decodes to UnsupportedValue', () {
      final field = decodeField(<String, dynamic>{
        'id': 'fldR',
        'name': 'Rolled',
        'type': 'rollup',
        'options': <String, dynamic>{},
      });

      final decoded = decodeValue(field, 42);

      expect(decoded.getRight().toNullable(), isA<TeableUnsupportedValue>());
    });

    test('an unrecognized relationship throws', () {
      expect(
        () => Relationship.fromWire('manyToSome'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('listTables decodes the base', () async {
      final t = _RecordingTransport((_) => _fixture('tables.json'));
      final result = await _client(t).listTables();

      final tables = result.getRight().toNullable()!;
      expect(tables, hasLength(17));
      expect(tables.map((x) => x.name), contains('PT · Task'));
    });
  });

  group('cell decoding', () {
    late List<TeableField> fields;

    setUp(() {
      final json = jsonDecode(_fixture('fields-task.json')) as List;
      fields = [for (final f in json) decodeField(f as Map<String, dynamic>)];
    });

    List<Map<String, dynamic>> taskRows() {
      final raw =
          (jsonDecode(_fixture('records-task.json')) as Map)['records'] as List;
      return [
        for (final r in raw) (r as Map)['fields'] as Map<String, dynamic>,
      ];
    }

    test('decodes a real record', () {
      final rows = taskRows();
      final withAttachments = rows.firstWhere(
        (r) => r['Attachments'] != null,
        orElse: () => throw StateError('no record has attachments'),
      );

      final decoded = decodeRecord(
        fields,
        withAttachments,
      ).getRight().toNullable()!;

      expect(decoded['Name'], isA<TeableTextValue>());
      expect(decoded['Attachments'], isA<TeableAttachmentValue>());
    });

    test('manyOne link decodes to a one-element list', () {
      for (final cells in taskRows()) {
        if (cells['Project'] is Map) {
          final decoded = decodeRecord(fields, cells).getRight().toNullable()!;
          final value = decoded['Project'] as TeableLinkValue;
          expect(value.value, hasLength(1));
          expect(value.value.first.id, startsWith('rec'));
          expect(value.value.first.title, isNotEmpty);
          return;
        }
      }
      fail('no record in the fixture has a populated manyOne Project link');
    });

    test('oneMany link decodes to a list', () {
      for (final cells in taskRows()) {
        final subtasks = cells['PT · Task'];
        if (subtasks is List && subtasks.isNotEmpty) {
          final decoded = decodeRecord(fields, cells).getRight().toNullable()!;
          final value = decoded['PT · Task'] as TeableLinkValue;
          expect(value.value, isNotEmpty);
          expect(value.value.first.id, startsWith('rec'));
          return;
        }
      }
      fail('no record in the fixture has populated subtask links');
    });

    test('a null link cell decodes to an empty list', () {
      final project = fields.firstWhere((f) => f.name == 'Project');
      final decoded = decodeValue(project, null).getRight().toNullable()!;
      expect(decoded, isA<TeableLinkValue>());
      expect((decoded as TeableLinkValue).value, isEmpty);
    });

    test('an empty-array link cell decodes to an empty list', () {
      final subtasks = fields.firstWhere((f) => f.name == 'PT · Task');
      final decoded = decodeValue(
        subtasks,
        <dynamic>[],
      ).getRight().toNullable()!;
      expect((decoded as TeableLinkValue).value, isEmpty);
    });

    test('attachment carries token and mimetype', () {
      for (final cells in taskRows()) {
        final atts = cells['Attachments'];
        if (atts is List && atts.isNotEmpty) {
          final decoded = decodeRecord(fields, cells).getRight().toNullable()!;
          final value = decoded['Attachments'] as TeableAttachmentValue;
          expect(value.value.first.token, isNotEmpty);
          expect(value.value.first.mimetype, isNotEmpty);
          return;
        }
      }
      fail('no record in the fixture has attachments');
    });

    test('every declared field appears in the decoded map', () {
      final rows = taskRows();
      final sparse = rows.firstWhere(
        (r) => r['Attachments'] == null,
        orElse: () =>
            throw StateError('no record has an unset Attachments cell'),
      );

      final decoded = decodeRecord(fields, sparse).getRight().toNullable()!;

      // The key exists even though the record did not carry it.
      expect(decoded.containsKey('Attachments'), isTrue);
      expect(decoded['Attachments'], isA<TeableAttachmentValue>());
      expect((decoded['Attachments']! as TeableAttachmentValue).value, isEmpty);

      // The decoded shape is the schema, not the data: every field is present.
      expect(decoded.keys.toSet(), fields.map((f) => f.name).toSet());
    });

    test('an absent date decodes to a null payload, not a missing key', () {
      final rows = taskRows();
      final noDue = rows.firstWhere(
        (r) => r['Due Date'] == null,
        orElse: () => throw StateError('no record has an unset Due Date'),
      );

      final decoded = decodeRecord(fields, noDue).getRight().toNullable()!;

      expect(decoded['Due Date'], isA<TeableDateValue>());
      expect((decoded['Due Date']! as TeableDateValue).value, isNull);
    });

    test('a present date and an absent date are distinguishable', () {
      final rows = taskRows();
      final withDue = rows.firstWhere(
        (r) => r['Due Date'] != null,
        orElse: () => throw StateError('no record has a Due Date'),
      );

      final decoded = decodeRecord(fields, withDue).getRight().toNullable()!;

      expect((decoded['Due Date']! as TeableDateValue).value, isNotNull);
    });

    test('a record with an unknown field key fails', () {
      final failure = decodeRecord(fields, {'NotAField': 'x'});
      expect(failure.isLeft(), isTrue);
    });

    test('a malformed date returns Left, not a throw', () {
      final due = fields.firstWhere((f) => f.name == 'Due Date');
      final result = decodeValue(due, 'not-a-date');
      expect(result.isLeft(), isTrue);
    });
  });
}
