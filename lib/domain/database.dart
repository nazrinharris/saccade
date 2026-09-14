import 'package:equatable/equatable.dart';

import 'field.dart';

/// A table, as Saccade models it.
class Database extends Equatable {
  final String id;
  final String name;
  final List<Field> fields;

  const Database({required this.id, required this.name, required this.fields});

  Field? fieldById(String fieldId) {
    for (final f in fields) {
      if (f.id == fieldId) return f;
    }
    return null;
  }

  @override
  List<Object?> get props => [id, name, fields];
}
