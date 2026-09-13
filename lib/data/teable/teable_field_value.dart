/// A decoded cell value. One variant per supported kind,
/// plus one for kinds Teable has but Saccade does not yet support.
sealed class TeableFieldValue {
  const TeableFieldValue();
}

class TeableTextValue extends TeableFieldValue {
  final String? value;
  const TeableTextValue(this.value);
}

class TeableNumberValue extends TeableFieldValue {
  final num? value;
  const TeableNumberValue(this.value);
}

class TeableDateValue extends TeableFieldValue {
  final DateTime? value;
  const TeableDateValue(this.value);
}

class TeableSelectValue extends TeableFieldValue {
  final String? value;
  const TeableSelectValue(this.value);
}

class TeableCheckboxValue extends TeableFieldValue {
  final bool? value;
  const TeableCheckboxValue(this.value);
}

/// Always a list, regardless of the field's cardinality.
class TeableLinkValue extends TeableFieldValue {
  final List<TeableLink> value;
  const TeableLinkValue(this.value);
}

/// Read-only in v1.
class TeableAttachmentValue extends TeableFieldValue {
  final List<TeableAttachment> value;
  const TeableAttachmentValue(this.value);
}

/// A kind Teable has that Saccade does not support. Carries the raw
/// type string so it can be rendered as "Rollup (unsupported)".
class TeableUnsupportedValue extends TeableFieldValue {
  final String type;
  const TeableUnsupportedValue(this.type);
}

class TeableLink {
  final String id;
  final String title;
  const TeableLink({required this.id, required this.title});
}

class TeableAttachment {
  final String id;
  final String name;
  final int size;
  final String mimetype;
  final String token;
  final int? width;
  final int? height;
  const TeableAttachment({
    required this.id,
    required this.name,
    required this.size,
    required this.mimetype,
    required this.token,
    this.width,
    this.height,
  });
}
