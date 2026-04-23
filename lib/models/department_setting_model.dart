class DepartmentSettingModel {
  const DepartmentSettingModel({this.id, required this.name});

  final String? id;
  final String name;

  factory DepartmentSettingModel.fromJson(Map<String, dynamic> json) {
    return DepartmentSettingModel(
      id: _readNullableString(json, const ['id', 'department_id']),
      name: _readString(json, const [
        'name',
        'department_name',
        'departmentName',
      ]),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'name': name.trim()};
  }

  static String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null) {
        return value.toString().trim();
      }
    }
    return '';
  }

  static String? _readNullableString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final value = _readString(json, keys);
    return value.isEmpty ? null : value;
  }
}
