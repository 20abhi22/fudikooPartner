class SupportInformationModel {
  final bool status;
  final String contactEmail;
  final String whatsappLink;
  final String contactUsPhone;

  const SupportInformationModel({
    required this.status,
    required this.contactEmail,
    required this.whatsappLink,
    required this.contactUsPhone,
  });

  factory SupportInformationModel.fromJson(Map<String, dynamic> json) {
    final status = json['status'];

    return SupportInformationModel(
      status: status == true || status == 1 || status == '1',
      contactEmail: (json['contact_email'] ?? '').toString(),
      whatsappLink: (json['whatsapp_link'] ?? '').toString(),
      contactUsPhone: (json['contact_us_phone'] ?? '').toString(),
    );
  }
}
