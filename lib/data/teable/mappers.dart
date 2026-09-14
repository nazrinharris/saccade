import '../../domain/field.dart';
import '../../domain/field_value.dart';
import '../../domain/record.dart';

import 'teable_field.dart';
import 'teable_field_value.dart';

/// The only file that knows both sides: Teable DTOs and Saccade domain types.
///
/// Everything above this file speaks domain. Everything below speaks Teable.
/// A backend swap deletes `lib/data/teable/` including this file, and nothing
/// above it changes.

/// Map a field definition DTO to the domain type.
Field toDomainField(TeableField dto) {
  return Field(
    id: dto.id,
    name: dto.name,
    type: dto.type,
    options: _toDomainOptions(dto.options),
    isPrimary: dto.isPrimary,
    isMultipleCellValue: dto.isMultipleCellValue,
  );
}

FieldOptions _toDomainOptions(TeableFieldOptions dto) {
  switch (dto) {
    case TeableNoOptions():
      return const NoOptions();
    case TeableNumberFieldOptions():
      return NumberFieldOptions(
        formattingType: _toDomainFormattingType(dto.formattingType),
        precision: dto.precision,
      );
    case TeableDateFieldOptions():
      return DateFieldOptions(
        dateFormat: dto.dateFormat,
        timeFormat: dto.timeFormat,
        timeZone: dto.timeZone,
      );
    case TeableSelectFieldOptions():
      return SelectFieldOptions(
        choices: [
          for (final c in dto.choices) SelectChoice(id: c.id, name: c.name),
        ],
      );
    case TeableLinkFieldOptions():
      return LinkFieldOptions(
        cardinality: _toDomainCardinality(dto.relationship),
        foreignTableId: dto.foreignTableId,
        symmetricFieldId: dto.symmetricFieldId,
      );
  }
}

/// The four legal values, translated explicitly. A new Teable relationship
/// is a compile error here rather than a silent passthrough.
Cardinality _toDomainCardinality(TeableRelationship relationship) {
  switch (relationship) {
    case TeableRelationship.oneOne:
      return Cardinality.oneToOne;
    case TeableRelationship.oneMany:
      return Cardinality.oneToMany;
    case TeableRelationship.manyOne:
      return Cardinality.manyToOne;
    case TeableRelationship.manyMany:
      return Cardinality.manyToMany;
  }
}

NumberFormattingType? _toDomainFormattingType(
  TeableNumberFormattingType? type,
) {
  if (type == null) return null;
  switch (type) {
    case TeableNumberFormattingType.decimal:
      return NumberFormattingType.decimal;
  }
}

/// Map a decoded cell DTO to the domain type.
///
/// No casts: the sealed DTO already carries a typed payload per variant.
FieldValue toDomainValue(TeableFieldValue dto) {
  switch (dto) {
    case TeableTextValue():
      return TextValue(dto.value);
    case TeableNumberValue():
      return NumberValue(dto.value);
    case TeableDateValue():
      return DateValue(dto.value);
    case TeableSelectValue():
      return SelectValue(dto.value);
    case TeableCheckboxValue():
      return CheckboxValue(dto.value);
    case TeableLinkValue():
      return LinkValue([
        for (final l in dto.value) Link(id: l.id, title: l.title),
      ]);
    case TeableAttachmentValue():
      return AttachmentValue([
        for (final a in dto.value)
          Attachment(
            id: a.id,
            name: a.name,
            size: a.size,
            mimetype: a.mimetype,
            token: a.token,
            width: a.width,
            height: a.height,
          ),
      ]);
    case TeableUnsupportedValue():
      return UnsupportedValue(dto.type);
  }
}

/// Map a decoded record to the domain type, rekeying values from field name
/// to stable field id.
///
/// [fields] is the already-mapped field list of the record's own table. Names
/// are unique within a table, so the lookup resolves unambiguously; a name
/// that matches nothing is a programming error upstream, not runtime data.
Record toDomainRecord(
  String id,
  Map<String, TeableFieldValue> decoded,
  List<Field> fields,
) {
  final values = <String, FieldValue>{};
  for (final field in fields) {
    final raw = decoded[field.name];
    if (raw == null) {
      throw StateError(
        'Decoded record is missing field "${field.name}" (${field.id})',
      );
    }
    values[field.id] = toDomainValue(raw);
  }
  return Record(id: id, values: values);
}
