class Station {
  const Station({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isOpen,
    this.hours,
    this.contact,
    this.address,
    this.source,
    this.sourceId,
    this.category,
    this.photoUrl,
    this.photoAttribution,
    this.verificationStatus = VerificationStatus.unverified,
    this.lastVerified,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final bool? isOpen;
  final String? hours;
  final String? contact;
  final String? address;
  final String? source;
  final String? sourceId;
  final String? category;
  final String? photoUrl;
  final String? photoAttribution;
  final VerificationStatus verificationStatus;
  final DateTime? lastVerified;

  bool get isVerified =>
      verificationStatus == VerificationStatus.verified ||
      verificationStatus == VerificationStatus.manuallyVerified;

  factory Station.fromMap(String id, Map<String, dynamic> data) {
    final latitude = (data['latitude'] as num?)?.toDouble();
    final longitude = (data['longitude'] as num?)?.toDouble();
    if (latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw FormatException('Station $id has invalid coordinates.');
    }
    final name = data['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      throw FormatException('Station $id has no name.');
    }

    return Station(
      id: id,
      name: name.trim(),
      latitude: latitude,
      longitude: longitude,
      isOpen: data['isOpen'] as bool?,
      hours: _optionalString(data['hours']),
      contact: _optionalString(data['contact']),
      address: _optionalString(data['address']),
      source: _optionalString(data['source']),
      sourceId: _optionalString(data['sourceId']),
      category: _optionalString(data['category']),
      photoUrl: _optionalString(data['photoUrl']),
      photoAttribution: _optionalString(data['photoAttribution']),
      verificationStatus: VerificationStatus.parse(
        data['verificationStatus'] as String?,
      ),
      lastVerified: _parseDate(data['lastVerified']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        if (isOpen != null) 'isOpen': isOpen,
        if (hours != null) 'hours': hours,
        if (contact != null) 'contact': contact,
        if (address != null) 'address': address,
        if (source != null) 'source': source,
        if (sourceId != null) 'sourceId': sourceId,
        if (category != null) 'category': category,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (photoAttribution != null) 'photoAttribution': photoAttribution,
        'verificationStatus': verificationStatus.value,
        if (lastVerified != null)
          'lastVerified': lastVerified!.toUtc().toIso8601String(),
      };

  static DateTime? _parseDate(Object? value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static String? _optionalString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }
}

enum VerificationStatus {
  unverified('unverified'),
  verified('verified'),
  manuallyVerified('manually_verified');

  const VerificationStatus(this.value);

  final String value;

  static VerificationStatus parse(String? value) {
    return VerificationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => VerificationStatus.unverified,
    );
  }
}
