class ContactData {
  final String name;
  final String phone;
  bool isSelected;

  ContactData({
    required this.name,
    required this.phone,
    this.isSelected = true,
  });
}
