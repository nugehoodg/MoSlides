import 'dart:convert';

class Presentation {
  final String id;
  String title;
  String content;
  DateTime lastEdited;
  String theme;
  String size;
  String fontSize;

  Presentation({
    required this.id,
    required this.title,
    required this.content,
    required this.lastEdited,
    this.theme = 'default',
    this.size = '1360x768',
    this.fontSize = 'Medium',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'lastEdited': lastEdited.toIso8601String(),
        'theme': theme,
        'size': size,
        'fontSize': fontSize,
      };

  factory Presentation.fromJson(Map<String, dynamic> json) => Presentation(
        id: json['id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        lastEdited: DateTime.parse(json['lastEdited'] as String),
        theme: (json['theme'] as String?) ?? 'default',
        size: (json['size'] as String?) ?? '1360x768',
        fontSize: (json['fontSize'] as String?) ?? 'Medium',
      );

  factory Presentation.fromJsonString(String s) =>
      Presentation.fromJson(jsonDecode(s) as Map<String, dynamic>);

  String toJsonString() => jsonEncode(toJson());

  Presentation copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? lastEdited,
    String? theme,
    String? size,
    String? fontSize,
  }) =>
      Presentation(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        lastEdited: lastEdited ?? this.lastEdited,
        theme: theme ?? this.theme,
        size: size ?? this.size,
        fontSize: fontSize ?? this.fontSize,
      );

  String get formattedDate {
    final d = lastEdited;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
