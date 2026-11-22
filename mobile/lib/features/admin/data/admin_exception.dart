class AdminException implements Exception {
  final String message;
  final String code;

  const AdminException(this.message, {this.code = 'ERROR'});

  @override
  String toString() => message;
}