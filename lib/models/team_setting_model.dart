class TeamSettingModel {
  const TeamSettingModel({
    this.id,
    required this.name,
    required this.description,
    this.iconUrl = '',
    this.existingIconPath = '',
    this.newIconPath = '',
  });

  final String? id;
  final String name;
  final String description;
  final String iconUrl;
  final String existingIconPath;
  final String newIconPath;

  factory TeamSettingModel.fromJson(Map<String, dynamic> json) {
    return TeamSettingModel(
      id: _readNullableString(json, const ['id', 'team_id']),
      name: _readString(json, const ['name', 'team_name', 'teamName']),
      description: _readString(json, const ['description', 'details']),
      iconUrl: _readString(json, const ['icon_url', 'iconUrl', 'icon']),
      existingIconPath: _readString(json, const [
        'existing_icon_path',
        'existingIconPath',
        'icon_path',
        'iconPath',
      ]),
      newIconPath: '',
    );
  }

  TeamSettingModel copyWith({
    String? id,
    String? name,
    String? description,
    String? iconUrl,
    String? existingIconPath,
    String? newIconPath,
  }) {
    return TeamSettingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconUrl: iconUrl ?? this.iconUrl,
      existingIconPath: existingIconPath ?? this.existingIconPath,
      newIconPath: newIconPath ?? this.newIconPath,
    );
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
