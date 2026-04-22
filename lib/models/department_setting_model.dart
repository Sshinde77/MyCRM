class DepartmentSettingModel {
  const DepartmentSettingModel({required this.name});

  final String name;

  factory DepartmentSettingModel.fromJson(Map<String, dynamic> json) {
    return DepartmentSettingModel(
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
}
