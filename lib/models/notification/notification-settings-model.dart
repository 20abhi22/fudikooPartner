class NotificationSettingsModel {
  bool remindOrdersIn10Mins;
  bool partyOrders;
  bool remindConfirmedOrders;

  NotificationSettingsModel({
    required this.remindOrdersIn10Mins,
    required this.partyOrders,
    required this.remindConfirmedOrders,
  });

  factory NotificationSettingsModel.fromJson(Map<String, dynamic> json) {
    return NotificationSettingsModel(
      remindOrdersIn10Mins: json['remind_orders_in_10_mins'] ?? false,
      partyOrders: json['party_orders'] ?? false,
      remindConfirmedOrders: json['remind_confirmed_orders'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'remind_orders_in_10_mins': remindOrdersIn10Mins,
    'party_orders': partyOrders,
    'remind_confirmed_orders': remindConfirmedOrders,
  };
}