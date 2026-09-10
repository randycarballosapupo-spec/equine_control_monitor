class AppUser {
  const AppUser({
    this.id,
    required this.email,
    this.password = '',
    required this.name,
    required this.roles,
    required this.stableName,
    required this.status,
    this.isPrimary = false,
    this.isOwner = false,
  });

  final String? id;
  final String email;
  final String password;
  final String name;
  final List<String> roles;
  final String stableName;
  final String status;
  final bool isPrimary;
  final bool isOwner;

  bool get isApproved => status == 'approved';
  bool get isAdmin => roles.contains('admin');

  AppUser copyWith({String? status, bool? isPrimary}) => AppUser(
        id: id,
        email: email,
        password: password,
        name: name,
        roles: roles,
        stableName: stableName,
        status: status ?? this.status,
        isPrimary: isPrimary ?? this.isPrimary,
      );

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'name': name,
        'roles': roles,
        'stableName': stableName,
        'status': status,
        'isPrimary': isPrimary,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final storedRoles = List<String>.from(json['roles'] as List? ?? const []);
    final roles = storedRoles
        .map((role) => role == 'stable_owner' ? 'admin' : role)
        .toSet()
        .toList();
    return AppUser(
      email: '${json['email'] ?? ''}',
      password: '${json['password'] ?? ''}',
      name: '${json['name'] ?? ''}',
      roles: roles,
      stableName: '${json['stableName'] ?? ''}',
      status: '${json['status'] ?? 'pending'}',
      isPrimary: json['isPrimary'] == true,
    );
  }

  factory AppUser.fromProfileRow(Map<String, dynamic> row) {
    final storedRoles = List<String>.from(row['roles'] as List? ?? const []);
    return AppUser(
      id: '${row['id'] ?? ''}',
      email: '${row['email'] ?? ''}',
      name: '${row['name'] ?? ''}',
      roles: storedRoles,
      stableName: '${row['stable_name'] ?? ''}',
      status: '${row['status'] ?? 'pending'}',
      isPrimary: row['is_primary'] == true,
      isOwner: row['is_owner'] == true,
    );
  }
}
