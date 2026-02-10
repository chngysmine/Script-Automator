class SASUPPadding {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const SASUPPadding({
    this.left = 0,
    this.top = 0,
    this.right = 0,
    this.bottom = 0,
  });

  factory SASUPPadding.all(double value) =>
      SASUPPadding(left: value, top: value, right: value, bottom: value);

  factory SASUPPadding.symmetric({
    double vertical = 0,
    double horizontal = 0,
  }) => SASUPPadding(
    left: horizontal,
    top: vertical,
    right: horizontal,
    bottom: vertical,
  );

  factory SASUPPadding.only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) => SASUPPadding(left: left, top: top, right: right, bottom: bottom);

  // Custom flexible Deserializer
  factory SASUPPadding.fromJson(dynamic json) {
    if (json is num) {
      return SASUPPadding.all(json.toDouble());
    }
    if (json is Map<String, dynamic>) {
      if (json.containsKey('value')) {
        return SASUPPadding.all((json['value'] as num).toDouble());
      }
      if (json.containsKey('vertical') || json.containsKey('horizontal')) {
        return SASUPPadding.symmetric(
          vertical: (json['vertical'] as num?)?.toDouble() ?? 0,
          horizontal: (json['horizontal'] as num?)?.toDouble() ?? 0,
        );
      }
      return SASUPPadding.only(
        left: (json['left'] as num?)?.toDouble() ?? 0,
        top: (json['top'] as num?)?.toDouble() ?? 0,
        right: (json['right'] as num?)?.toDouble() ?? 0,
        bottom: (json['bottom'] as num?)?.toDouble() ?? 0,
      );
    }
    return const SASUPPadding();
  }

  Map<String, dynamic> toJson() => {
    'left': left,
    'top': top,
    'right': right,
    'bottom': bottom,
  };
}
