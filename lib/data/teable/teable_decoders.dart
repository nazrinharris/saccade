import 'package:fpdart/fpdart.dart';

import 'teable_field.dart';
import 'teable_field_value.dart';

/// Runtime decode failures.
///
/// Programming errors (unknown kind, unrecognized enum value) throw instead;
/// these are for malformed data.
sealed class TeableDecodeFailure {
  final String message;
  const TeableDecodeFailure(this.message);
}

class MalformedCellFailure extends TeableDecodeFailure {
  const MalformedCellFailure(super.message);
}

/// The 8 kinds v1 decodes.
const _supportedKinds = {
  'singleLineText',
  'longText',
  'number',
  'date',
  'singleSelect',
  'checkbox',
  'link',
  'attachment',
};

/// The 12 remaining kinds Teable can emit. Recognized, not supported.
const _knownUnsupportedKinds = {
  'user',
  'multipleSelect',
  'rating',
  'formula',
  'rollup',
  'conditionalRollup',
  'createdTime',
  'lastModifiedTime',
  'createdBy',
  'lastModifiedBy',
  'autoNumber',
  'button',
};

/// Guard: every supported kind must have a case in both switches below.
/// Catches the bug of adding a kind to the set and forgetting its case.
void _assertSupportedKindHasCase(String type) {
  if (_supportedKinds.contains(type)) {
    throw StateError(
      'Kind "$type" is in _supportedKinds but has no decoder case',
    );
  }
}

/// Decode a field definition. Source: GET /api/table/{id}/field
TeableField decodeField(Map<String, dynamic> json) {
  final type = json['type'] as String;
  return TeableField(
    id: json['id'] as String,
    name: json['name'] as String,
    type: type,
    options: _decodeOptions(
      type,
      json['options'] as Map<String, dynamic>? ?? const {},
    ),
    isPrimary: json['isPrimary'] as bool? ?? false,
    isMultipleCellValue: json['isMultipleCellValue'] as bool? ?? false,
  );
}

TeableFieldOptions _decodeOptions(String type, Map<String, dynamic> raw) {
  switch (type) {
    case 'singleLineText':
    case 'longText':
    case 'checkbox':
    case 'attachment':
      return const NoOptions();
    case 'number':
      final f = raw['formatting'] as Map<String, dynamic>?;
      final fmt = f?['type'] as String?;
      return NumberFieldOptions(
        formattingType: fmt == null ? null : NumberFormattingType.fromWire(fmt),
        precision: f?['precision'] as int?,
      );
    case 'date':
      final f = raw['formatting'] as Map<String, dynamic>?;
      return DateFieldOptions(
        dateFormat: f?['date'] as String?,
        timeFormat: f?['time'] as String?,
        timeZone: f?['timeZone'] as String?,
      );
    case 'singleSelect':
      final choices = (raw['choices'] as List?) ?? const [];
      return SelectFieldOptions(
        choices: [
          for (final c in choices)
            TeableSelectChoice(
              id: (c as Map)['id'] as String,
              name: c['name'] as String,
            ),
        ],
      );
    case 'link':
      return LinkFieldOptions(
        relationship: Relationship.fromWire(raw['relationship'] as String),
        foreignTableId: raw['foreignTableId'] as String,
        symmetricFieldId: raw['symmetricFieldId'] as String,
      );
    default:
      if (_knownUnsupportedKinds.contains(type)) {
        return const NoOptions();
      }
      _assertSupportedKindHasCase(type);
      throw ArgumentError('Unknown Teable field kind: $type');
  }
}

/// Decode one cell value. `raw` is any JSON value: its shape depends
/// on the field's kind, which is why the field is required.
Either<TeableDecodeFailure, TeableFieldValue> decodeValue(
  TeableField field,
  dynamic raw,
) {
  try {
    switch (field.type) {
      case 'singleLineText':
      case 'longText':
        return Right(TeableTextValue(raw as String?));
      case 'number':
        return Right(TeableNumberValue(raw as num?));
      case 'date':
        final s = raw as String?;
        return Right(TeableDateValue(s == null ? null : DateTime.parse(s)));
      case 'singleSelect':
        return Right(TeableSelectValue(raw as String?));
      case 'checkbox':
        return Right(TeableCheckboxValue(raw as bool?));
      case 'link':
        return Right(TeableLinkValue(_decodeLinks(raw)));
      case 'attachment':
        return Right(TeableAttachmentValue(_decodeAttachments(raw)));
      default:
        if (_knownUnsupportedKinds.contains(field.type)) {
          return Right(TeableUnsupportedValue(field.type));
        }
        _assertSupportedKindHasCase(field.type);
        throw ArgumentError('Unknown Teable field kind: ${field.type}');
    }
  } on FormatException catch (e) {
    return Left(
      MalformedCellFailure('Bad value for ${field.type}: ${e.message}'),
    );
  } on TypeError catch (e) {
    return Left(MalformedCellFailure('Wrong cell type for ${field.type}: $e'));
  }
}

/// Normalizes all four raw shapes (object, array, null, empty array)
/// into a list.
List<TeableLink> _decodeLinks(dynamic raw) {
  if (raw == null) return const [];
  final items = raw is List ? raw : [raw];
  return [
    for (final item in items)
      TeableLink(
        id: (item as Map)['id'] as String,
        title: item['title'] as String? ?? '',
      ),
  ];
}

List<TeableAttachment> _decodeAttachments(dynamic raw) {
  if (raw == null) return const [];
  return [
    for (final item in raw as List)
      TeableAttachment(
        id: (item as Map)['id'] as String,
        name: item['name'] as String,
        size: item['size'] as int,
        mimetype: item['mimetype'] as String,
        token: item['token'] as String,
        width: item['width'] as int?,
        height: item['height'] as int?,
      ),
  ];
}

/// Decode every cell in a record against its table's field definitions.
Either<TeableDecodeFailure, Map<String, TeableFieldValue>> decodeRecord(
  List<TeableField> fields,
  Map<String, dynamic> rawRecord,
) {
  final byName = {for (final f in fields) f.name: f};
  final out = <String, TeableFieldValue>{};
  for (final entry in rawRecord.entries) {
    final field = byName[entry.key];
    if (field == null) {
      return Left(
        MalformedCellFailure('Record has unknown field "${entry.key}"'),
      );
    }
    final decoded = decodeValue(field, entry.value);
    if (decoded case Left(value: final failure)) {
      return Left(failure);
    }
    out[entry.key] = decoded.getRight().toNullable()!;
  }
  return Right(out);
}
