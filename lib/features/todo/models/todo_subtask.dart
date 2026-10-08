class TodoSubtask {
  final String id;
  final String title;
  final bool isCompleted;

  const TodoSubtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  TodoSubtask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return TodoSubtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
      };

  factory TodoSubtask.fromJson(Map<String, dynamic> json) => TodoSubtask(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: (json['isCompleted'] as bool?) ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoSubtask &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ isCompleted.hashCode;
}
