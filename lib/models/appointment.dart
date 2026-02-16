class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime dateTime;
  final String status;
  final String? notes;
  final String? prescription;
  final double? fee;
  final String? meetingLink;
  final Map<String, dynamic>? patientDetails;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.dateTime,
    this.status = 'scheduled',
    this.notes,
    this.prescription,
    this.fee,
    this.meetingLink,
    this.patientDetails,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      doctorId: json['doctorId'],
      patientId: json['patientId'],
      dateTime: DateTime.parse(json['dateTime']),
      status: json['status'] ?? 'scheduled',
      notes: json['notes'],
      prescription: json['prescription'],
      fee: json['fee']?.toDouble(),
      meetingLink: json['meetingLink'],
      patientDetails: json['patientDetails'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'dateTime': dateTime.toIso8601String(),
      'status': status,
      'notes': notes,
      'prescription': prescription,
      'fee': fee,
      'meetingLink': meetingLink,
      'patientDetails': patientDetails,
    };
  }
}
