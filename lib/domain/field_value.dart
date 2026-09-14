import 'package:equatable/equatable.dart';

/// A cell value in Saccade's own vocabulary.
/// One variant per supported kind, plus one for kinds Teable has
/// that Saccade does not yet support.
sealed class FieldValue extends Equatable {
  const FieldValue();
}

class TextValue extends FieldValue {
  final String? value;
  const TextValue(this.value);

  @override
  List<Object?> get props => [value];
}

class NumberValue extends FieldValue {
  final num? value;
  const NumberValue(this.value);

  @override
  List<Object?> get props => [value];
}

class DateValue extends FieldValue {
  final DateTime? value;
  const DateValue(this.value);

  @override
  List<Object?> get props => [value];
}

class SelectValue extends FieldValue {
  final String? value;
  const SelectValue(this.value);

  @override
  List<Object?> get props => [value];
}

class CheckboxValue extends FieldValue {
  final bool? value;
  const CheckboxValue(this.value);

  @override
  List<Object?> get props => [value];
}

/// Always a list, regardless of the field's cardinality.
class LinkValue extends FieldValue {
  final List<Link> value;
  const LinkValue(this.value);

  @override
  List<Object?> get props => [value];
}

/// Read-only in v1.
class AttachmentValue extends FieldValue {
  final List<Attachment> value;
  const AttachmentValue(this.value);

  @override
  List<Object?> get props => [value];
}

/// A kind Teable has that Saccade does not support. Carries the raw
/// type string so it can be rendered as "Rollup (unsupported)".
class UnsupportedValue extends FieldValue {
  final String type;
  const UnsupportedValue(this.type);

  @override
  List<Object?> get props => [type];
}

class Link extends Equatable {
  final String id;
  final String title;
  const Link({required this.id, required this.title});

  @override
  List<Object?> get props => [id, title];
}

class Attachment extends Equatable {
  final String id;
  final String name;
  final int size;
  final String mimetype;
  final String token;
  final int? width;
  final int? height;
  const Attachment({
    required this.id,
    required this.name,
    required this.size,
    required this.mimetype,
    required this.token,
    this.width,
    this.height,
  });

  @override
  List<Object?> get props => [id, name, size, mimetype, token, width, height];
}
