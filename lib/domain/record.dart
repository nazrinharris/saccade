import 'package:equatable/equatable.dart';

import 'field_value.dart';

/// A record's values, keyed by stable field id, not by field name.
class Record extends Equatable {
  final String id;
  final Map<String, FieldValue> values;

  const Record({required this.id, required this.values});

  FieldValue? valueOf(String fieldId) => values[fieldId];

  @override
  List<Object?> get props => [id, values];
}
