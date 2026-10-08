import 'package:small_husn_muslim/l10n/app_localizations.dart';

enum TodoFilterType {
  all,
  today,
  upcoming,
  important,
  overdue,
  completed;

  String label(AppLocalizations loc) => switch (this) {
        TodoFilterType.all => loc.todoFilterAll,
        TodoFilterType.today => loc.todoFilterToday,
        TodoFilterType.upcoming => loc.todoFilterUpcoming,
        TodoFilterType.important => loc.todoFilterImportant,
        TodoFilterType.overdue => loc.todoFilterOverdue,
        TodoFilterType.completed => loc.todoCompletedSection,
      };
}

enum TodoSortType {
  manual,
  dueDate,
  priority,
  title,
  createdAt;

  String label(AppLocalizations loc) => switch (this) {
        TodoSortType.manual => loc.todoSortManual,
        TodoSortType.dueDate => loc.todoSortDueDate,
        TodoSortType.priority => loc.todoSortPriority,
        TodoSortType.title => loc.todoSortTitle,
        TodoSortType.createdAt => loc.todoSortCreatedAt,
      };
}
