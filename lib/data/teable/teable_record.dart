/// A record as Teable sent it: stable id plus raw cell values.
/// Cells are decoded later, once field definitions are in hand.
class TeableRecordDto {
  final String id;
  final Map<String, dynamic> fields;

  const TeableRecordDto({required this.id, required this.fields});
}
