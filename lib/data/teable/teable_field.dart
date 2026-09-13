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
class NoOptions extends TeableFieldOptions {
  const NoOptions();
}

class NumberFieldOptions extends TeableFieldOptions {
  final NumberFormattingType? formattingType;
  final int? precision;

  const NumberFieldOptions({this.formattingType, this.precision});
}

class DateFieldOptions extends TeableFieldOptions {
  final String? dateFormat;
  final String? timeFormat;
  final String? timeZone;

  const DateFieldOptions({this.dateFormat, this.timeFormat, this.timeZone});
}

class SelectFieldOptions extends TeableFieldOptions {
  final List<TeableSelectChoice> choices;

  const SelectFieldOptions({required this.choices});
}

class LinkFieldOptions extends TeableFieldOptions {
  final Relationship relationship;
  final String foreignTableId;
  final String symmetricFieldId;

  const LinkFieldOptions({
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
enum Relationship {
  oneOne('oneOne'),
  oneMany('oneMany'),
  manyOne('manyOne'),
  manyMany('manyMany');

  final String wire;
  const Relationship(this.wire);

  static Relationship fromWire(String value) {
    for (final r in Relationship.values) {
      if (r.wire == value) return r;
    }
    throw ArgumentError('Unrecognized link relationship: $value');
  }
}

/// Teable's number formatting. Values seen so far: decimal.
enum NumberFormattingType {
  decimal('decimal');

  final String wire;
  const NumberFormattingType(this.wire);

  static NumberFormattingType fromWire(String value) {
    for (final t in NumberFormattingType.values) {
      if (t.wire == value) return t;
    }
    throw ArgumentError('Unrecognized number formatting type: $value');
  }
}
