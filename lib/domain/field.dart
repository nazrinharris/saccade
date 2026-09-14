import 'package:equatable/equatable.dart';

/// A field definition, in Saccade's vocabulary.
class Field extends Equatable {
  final String id;
  final String name;
  final String type;
  final FieldOptions options;
  final bool isPrimary;
  final bool isMultipleCellValue;

  const Field({
    required this.id,
    required this.name,
    required this.type,
    required this.options,
    required this.isPrimary,
    required this.isMultipleCellValue,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    options,
    isPrimary,
    isMultipleCellValue,
  ];
}

/// Kind-specific field options.
sealed class FieldOptions extends Equatable {
  const FieldOptions();
}

/// singleLineText, longText, checkbox, attachment
class NoOptions extends FieldOptions {
  const NoOptions();

  @override
  List<Object?> get props => [];
}

class NumberFieldOptions extends FieldOptions {
  final NumberFormattingType? formattingType;
  final int? precision;

  const NumberFieldOptions({this.formattingType, this.precision});

  @override
  List<Object?> get props => [formattingType, precision];
}

class DateFieldOptions extends FieldOptions {
  final String? dateFormat;
  final String? timeFormat;
  final String? timeZone;

  const DateFieldOptions({this.dateFormat, this.timeFormat, this.timeZone});

  @override
  List<Object?> get props => [dateFormat, timeFormat, timeZone];
}

class SelectFieldOptions extends FieldOptions {
  final List<SelectChoice> choices;

  const SelectFieldOptions({required this.choices});

  @override
  List<Object?> get props => [choices];
}

class LinkFieldOptions extends FieldOptions {
  final Cardinality cardinality;
  final String foreignTableId;
  final String symmetricFieldId;

  const LinkFieldOptions({
    required this.cardinality,
    required this.foreignTableId,
    required this.symmetricFieldId,
  });

  @override
  List<Object?> get props => [cardinality, foreignTableId, symmetricFieldId];
}

class SelectChoice extends Equatable {
  final String id;
  final String name;

  const SelectChoice({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

/// How many records a link can point at.
enum Cardinality { oneToOne, oneToMany, manyToOne, manyToMany }

enum NumberFormattingType { decimal }
