class CctvData {
  final String streetName;
  final bool isOnline;
  final String? urlStream;

  const CctvData({
    required this.streetName,
    required this.isOnline,
    this.urlStream,
  });
}
