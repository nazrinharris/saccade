import 'package:equatable/equatable.dart';

import 'database.dart';

/// A group of databases.
class Workspace extends Equatable {
  final String id;
  final String name;
  final List<Database> databases;

  const Workspace({
    required this.id,
    required this.name,
    required this.databases,
  });

  @override
  List<Object?> get props => [id, name, databases];
}
