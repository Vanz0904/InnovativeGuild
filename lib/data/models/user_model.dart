enum UserRole {
  buyer,
  seller,
  admin;

  String get label {
    switch (this) {
      case UserRole.buyer:
        return 'Buyer';
      case UserRole.seller:
        return 'Seller';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
extension UserRoleX on UserRole {
  String get apiValue => name;

  String get label {
    switch (this) {
      case UserRole.buyer:
        return 'Buyer';
      case UserRole.seller:
        return 'Seller';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  static UserRole fromApi(String value) {
    switch (value) {
      case 'seller':
        return UserRole.seller;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.buyer;
    }
  }
}

class AppUser {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final UserRole role;
  final bool isVerified;
  final int trustScore;
  final bool twoFactorEnabled;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.isVerified,
    required this.trustScore,
    required this.twoFactorEnabled,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: UserRoleX.fromApi(json['role'] as String? ?? 'buyer'),
      isVerified: json['isVerified'] as bool? ?? false,
      trustScore: (json['trustScore'] as num?)?.toInt() ?? 0,
      twoFactorEnabled: json['twoFactorEnabled'] as bool? ?? false,
    );
  }
}

/// A lighter-weight user shape returned by seller search results.
class UserSummary {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final int trustScore;
  final bool isVerified;

  const UserSummary({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.trustScore,
    required this.isVerified,
  });

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as int,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      trustScore: (json['trustScore'] as num?)?.toInt() ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}
