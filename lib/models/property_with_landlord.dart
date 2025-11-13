import 'package:odiorent/models/property.dart';
import 'package:odiorent/models/admin_user.dart';

class PropertyWithLandlord {
  final Property property;
  final AdminUser landlord;

  PropertyWithLandlord({required this.property, required this.landlord});

  factory PropertyWithLandlord.fromMap(Map<String, dynamic> map) {
    return PropertyWithLandlord(
      property: Property.fromMap(map),
      landlord: AdminUser.fromMap(map['profiles']),
    );
  }
}
