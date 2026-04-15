class ProjectCommentModel {
  const ProjectCommentModel({
    required this.id,
    required this.comment,
    required this.userName,
    required this.userAvatarUrl,
    required this.createdAtRaw,
  });

  final String id;
  final String comment;
  final String userName;
  final String userAvatarUrl;
  final String createdAtRaw;

  factory ProjectCommentModel.fromJson(Map<String, dynamic> json) {
    final user = _readMap(json, const [
      'user',
      'author',
      'created_by',
      'createdBy',
      'staff',
      'member',
    ]);

    return ProjectCommentModel(
      id: _readValue(json, const ['id', 'comment_id', 'commentId']),
      comment: _readValue(json, const [
        'comment',
        'message',
        'text',
        'body',
        'content',
      ]),
      userName: _readValue(user.isNotEmpty ? user : json, const [
        'name',
        'full_name',
        'fullName',
        'staff_name',
        'author_name',
        'created_by_name',
        'createdByName',
      ], fallback: 'Unknown User'),
      userAvatarUrl: _readValue(user.isNotEmpty ? user : json, const [
        'avatar',
        'avatar_url',
        'avatarUrl',
        'image',
        'profile_image',
        'profileImage',
        'photo',
      ]),
      createdAtRaw: _readValue(json, const [
        'created_at',
        'createdAt',
        'date',
        'created_on',
      ]),
    );
  }

  static Map<String, dynamic> _readMap(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.map((k, v) => MapEntry(k.toString(), v));
      }
    }
    return const <String, dynamic>{};
  }

  static String _readValue(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) {
        continue;
      }

      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }

      if (value is num) {
        return value.toString();
      }
    }

    return fallback;
  }
}
