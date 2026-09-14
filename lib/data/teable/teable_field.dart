/// A field definition as Teable reports it.
/// Source: GET /api/table/{tableId}/field
class TeableField {
  final String id;
  final String name;
  final String type;
  final TeableFieldOptions options;
  final bool isPrimary;
  final bool isMultipleCellValue;

  TeableField({
    required this.id,
    required this.name,
    required this.type,
    required this.options,
    required this.isPrimary,
    required this.isMultipleCellValue,
  });
}

/// Kind-specific field options. Teable sends {} for kinds that have none.
sealed class TeableFieldOptions {
  const TeableFieldOptions();
}

/// singleLineText, longText, checkbox, attachment
class TeableNoOptions extends TeableFieldOptions {
  const TeableNoOptions();
}

class TeableNumberFieldOptions extends TeableFieldOptions {
  final TeableNumberFormattingType? formattingType;
  final int? precision;

  const TeableNumberFieldOptions({this.formattingType, this.precision});
}

class TeableDateFieldOptions extends TeableFieldOptions {
  final String? dateFormat;
  final String? timeFormat;
  final String? timeZone;

  const TeableDateFieldOptions({
    this.dateFormat,
    this.timeFormat,
    this.timeZone,
  });
}

class TeableSelectFieldOptions extends TeableFieldOptions {
  final List<TeableSelectChoice> choices;

  const TeableSelectFieldOptions({required this.choices});
}

class TeableLinkFieldOptions extends TeableFieldOptions {
  final TeableRelationship relationship;
  final String foreignTableId;
  final String symmetricFieldId;

  const TeableLinkFieldOptions({
    required this.relationship,
    required this.foreignTableId,
    required this.symmetricFieldId,
  });
}

class TeableSelectChoice {
  final String id;
  final String name;

  const TeableSelectChoice({required this.id, required this.name});
}

/// Teable's link cardinality. Exactly four legal values.
enum TeableRelationship {
  oneOne('oneOne'),
  oneMany('oneMany'),
  manyOne('manyOne'),
  manyMany('manyMany');

  final String wire;
  const TeableRelationship(this.wire);

  static TeableRelationship fromWire(String value) {
    for (final r in TeableRelationship.values) {
      if (r.wire == value) return r;
    }
    throw ArgumentError('Unrecognized link relationship: $value');
  }
}

/// Teable's number formatting. Values seen so far: decimal.
enum TeableNumberFormattingType {
  decimal('decimal');

  final String wire;
  const TeableNumberFormattingType(this.wire);

  static TeableNumberFormattingType fromWire(String value) {
    for (final t in TeableNumberFormattingType.values) {
      if (t.wire == value) return t;
    }
    throw ArgumentError('Unrecognized number formatting type: $value');
  }
}
