enum KnowledgeKind { background, wbs, spec, agenda, issue, commitment, other }

extension KnowledgeKindX on KnowledgeKind {
  String get label => switch (this) {
    KnowledgeKind.background => '專案背景',
    KnowledgeKind.wbs => 'WBS / 時程',
    KnowledgeKind.spec => 'API / 規格',
    KnowledgeKind.agenda => '會議議程',
    KnowledgeKind.issue => '已知 Issue',
    KnowledgeKind.commitment => '客戶承諾',
    KnowledgeKind.other => '其他文件',
  };
}

class KnowledgeDoc {
  const KnowledgeDoc({
    required this.relativePath,
    required this.kind,
    required this.byteLength,
    required this.included,
    required this.score,
  });

  final String relativePath;
  final KnowledgeKind kind;
  final int byteLength;
  final bool included;
  final int score;

  KnowledgeDoc copyWith({bool? included}) {
    return KnowledgeDoc(
      relativePath: relativePath,
      kind: kind,
      byteLength: byteLength,
      included: included ?? this.included,
      score: score,
    );
  }

  Map<String, Object?> toJson() => {
    'relativePath': relativePath,
    'kind': kind.name,
    'byteLength': byteLength,
    'included': included,
    'score': score,
  };

  factory KnowledgeDoc.fromJson(Map<String, dynamic> json) {
    return KnowledgeDoc(
      relativePath: json['relativePath']! as String,
      kind: KnowledgeKind.values.byName(json['kind']! as String),
      byteLength: json['byteLength']! as int,
      included: json['included']! as bool,
      score: json['score']! as int,
    );
  }
}

enum ProjectTaskStatus { planned, inProgress, blocked, done, uncertain }

extension ProjectTaskStatusX on ProjectTaskStatus {
  String get label => switch (this) {
    ProjectTaskStatus.planned => '預計',
    ProjectTaskStatus.inProgress => '進行中',
    ProjectTaskStatus.blocked => '阻塞',
    ProjectTaskStatus.done => '完成',
    ProjectTaskStatus.uncertain => '待確認',
  };
}

/// A delivery slice of the project board. Keep each phase small; archive it
/// when every task is done so the next phase starts with a clean board.
class ProjectPhase {
  const ProjectPhase({
    required this.id,
    required this.name,
    required this.sortOrder,
    this.archived = false,
    this.archivedAt,
  });

  final String id;
  final String name;
  final int sortOrder;
  final bool archived;
  final DateTime? archivedAt;

  ProjectPhase copyWith({
    String? name,
    int? sortOrder,
    bool? archived,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
  }) => ProjectPhase(
    id: id,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'sortOrder': sortOrder,
    'archived': archived,
    'archivedAt': archivedAt?.millisecondsSinceEpoch,
  };

  factory ProjectPhase.fromJson(Map<String, dynamic> json) => ProjectPhase(
    id: json['id'] as String,
    name: (json['name'] as String?)?.trim().isNotEmpty == true
        ? (json['name'] as String).trim()
        : '未命名階段',
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    archived: json['archived'] as bool? ?? false,
    archivedAt: json['archivedAt'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(json['archivedAt'] as int),
  );
}

class ProjectTask {
  const ProjectTask({
    required this.id,
    required this.title,
    required this.status,
    required this.updatedAt,
    this.phaseId,
    this.startDate,
    this.endDate,
    this.owner = '',
    this.sources = const [],
    this.confirmed = false,
  });

  final String id;
  final String title;
  final ProjectTaskStatus status;
  final DateTime updatedAt;
  final String? phaseId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String owner;
  final List<String> sources;
  final bool confirmed;

  ProjectTask copyWith({
    String? title,
    ProjectTaskStatus? status,
    String? phaseId,
    bool clearPhaseId = false,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStart = false,
    bool clearEnd = false,
    String? owner,
    List<String>? sources,
    bool? confirmed,
  }) => ProjectTask(
    id: id,
    title: title ?? this.title,
    status: status ?? this.status,
    updatedAt: DateTime.now(),
    phaseId: clearPhaseId ? null : (phaseId ?? this.phaseId),
    startDate: clearStart ? null : (startDate ?? this.startDate),
    endDate: clearEnd ? null : (endDate ?? this.endDate),
    owner: owner ?? this.owner,
    sources: sources ?? this.sources,
    confirmed: confirmed ?? this.confirmed,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'status': status.name,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'phaseId': phaseId,
    'startDate': startDate?.millisecondsSinceEpoch,
    'endDate': endDate?.millisecondsSinceEpoch,
    'owner': owner,
    'sources': sources,
    'confirmed': confirmed,
  };

  factory ProjectTask.fromJson(Map<String, dynamic> json) => ProjectTask(
    id: json['id'] as String,
    title: json['title'] as String,
    status: ProjectTaskStatus.values.firstWhere(
      (value) => value.name == json['status'],
      orElse: () => ProjectTaskStatus.uncertain,
    ),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(
      json['updatedAt'] as int? ?? 0,
    ),
    phaseId: json['phaseId'] as String?,
    startDate: json['startDate'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(json['startDate'] as int),
    endDate: json['endDate'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(json['endDate'] as int),
    owner: json['owner'] as String? ?? '',
    sources: List<String>.from(json['sources'] as List? ?? const []),
    confirmed: json['confirmed'] as bool? ?? false,
  );
}

class ProjectPack {
  const ProjectPack({
    required this.id,
    required this.folderPath,
    required this.name,
    required this.indexedAt,
    required this.docs,
    this.briefing,
    this.personalContext = '',
    this.transcriptionTerms = '',
    this.tasks = const [],
    this.phases = const [],
    this.activePhaseId,
  });

  final String id;
  final String folderPath;
  final String name;
  final DateTime indexedAt;
  final List<KnowledgeDoc> docs;
  final String? briefing;
  final String personalContext;
  final String transcriptionTerms;
  final List<ProjectTask> tasks;
  final List<ProjectPhase> phases;
  final String? activePhaseId;

  List<KnowledgeDoc> get includedDocs =>
      docs.where((doc) => doc.included).toList();

  int get includedCount => includedDocs.length;

  List<ProjectPhase> get openPhases =>
      phases.where((phase) => !phase.archived).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<ProjectPhase> get archivedPhases =>
      phases.where((phase) => phase.archived).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  ProjectPhase? get activePhase {
    if (activePhaseId != null) {
      for (final phase in phases) {
        if (phase.id == activePhaseId && !phase.archived) return phase;
      }
    }
    return openPhases.isEmpty ? null : openPhases.first;
  }

  List<ProjectTask> tasksInPhase(String? phaseId) => [
    for (final task in tasks)
      if (task.phaseId == phaseId) task,
  ];

  List<ProjectTask> get activePhaseTasks {
    final phase = activePhase;
    if (phase == null) return const [];
    return tasksInPhase(phase.id);
  }

  bool isPhaseComplete(String phaseId) {
    final items = tasksInPhase(phaseId);
    return items.isNotEmpty &&
        items.every((task) => task.status == ProjectTaskStatus.done);
  }

  /// Ensures legacy packs (tasks without phases) get a default open phase.
  ProjectPack withNormalizedPhases() {
    if (phases.isNotEmpty) {
      final phaseIds = {for (final phase in phases) phase.id};
      final repairedTasks = [
        for (final task in tasks)
          task.phaseId != null && phaseIds.contains(task.phaseId)
              ? task
              : task.copyWith(
                  phaseId: activePhase?.id ?? phases.first.id,
                ),
      ];
      final active =
          activePhaseId != null &&
              phases.any((phase) => phase.id == activePhaseId && !phase.archived)
          ? activePhaseId
          : openPhases.isEmpty
          ? null
          : openPhases.first.id;
      return copyWith(tasks: repairedTasks, activePhaseId: active);
    }
    if (tasks.isEmpty) return this;
    final phase = ProjectPhase(
      id: '${id}__phase_1',
      name: '階段 1',
      sortOrder: 0,
    );
    return copyWith(
      phases: [phase],
      activePhaseId: phase.id,
      tasks: [
        for (final task in tasks) task.copyWith(phaseId: phase.id),
      ],
    );
  }

  String nextPhaseName() {
    final numbers = <int>[
      for (final phase in phases)
        if (RegExp(r'^階段\s*(\d+)$').firstMatch(phase.name) case final match?)
          int.parse(match.group(1)!),
    ];
    final next = (numbers.isEmpty ? phases.length : numbers.reduce(mathMax)) + 1;
    return '階段 $next';
  }

  static int mathMax(int a, int b) => a > b ? a : b;

  ProjectPack copyWith({
    String? id,
    String? folderPath,
    String? name,
    DateTime? indexedAt,
    List<KnowledgeDoc>? docs,
    String? briefing,
    bool clearBriefing = false,
    String? personalContext,
    String? transcriptionTerms,
    List<ProjectTask>? tasks,
    List<ProjectPhase>? phases,
    String? activePhaseId,
    bool clearActivePhaseId = false,
  }) {
    return ProjectPack(
      personalContext: personalContext ?? this.personalContext,
      transcriptionTerms: transcriptionTerms ?? this.transcriptionTerms,
      tasks: tasks ?? this.tasks,
      phases: phases ?? this.phases,
      activePhaseId: clearActivePhaseId
          ? null
          : (activePhaseId ?? this.activePhaseId),
      id: id ?? this.id,
      folderPath: folderPath ?? this.folderPath,
      name: name ?? this.name,
      indexedAt: indexedAt ?? this.indexedAt,
      docs: docs ?? this.docs,
      briefing: clearBriefing ? null : (briefing ?? this.briefing),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'folderPath': folderPath,
    'name': name,
    'indexedAt': indexedAt.millisecondsSinceEpoch,
    'docs': docs.map((doc) => doc.toJson()).toList(),
    'briefing': briefing,
    'personalContext': personalContext,
    'transcriptionTerms': transcriptionTerms,
    'tasks': tasks.map((task) => task.toJson()).toList(),
    'phases': phases.map((phase) => phase.toJson()).toList(),
    'activePhaseId': activePhaseId,
  };

  factory ProjectPack.fromJson(Map<String, dynamic> json) {
    final rawDocs = json['docs'] as List<dynamic>? ?? const [];
    final folderPath = json['folderPath']! as String;
    final pack = ProjectPack(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? json['id'] as String
          : folderPath,
      folderPath: folderPath,
      name: json['name']! as String,
      indexedAt: DateTime.fromMillisecondsSinceEpoch(json['indexedAt']! as int),
      docs: rawDocs
          .map(
            (item) =>
                KnowledgeDoc.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      briefing: json['briefing'] as String?,
      personalContext: json['personalContext'] as String? ?? '',
      transcriptionTerms: json['transcriptionTerms'] as String? ?? '',
      tasks: [
        for (final item in json['tasks'] as List? ?? const [])
          ProjectTask.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      phases: [
        for (final item in json['phases'] as List? ?? const [])
          ProjectPhase.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      activePhaseId: json['activePhaseId'] as String?,
    );
    return pack.withNormalizedPhases();
  }
}

class ProjectLibrary {
  const ProjectLibrary({this.projects = const [], this.activeId});

  static const unassignedId = '__unassigned__';

  final List<ProjectPack> projects;
  final String? activeId;

  bool get hasSelection => active != null;

  ProjectPack? get active {
    if (activeId == null || activeId == unassignedId) return null;
    for (final project in projects) {
      if (project.id == activeId) return project;
    }
    return null;
  }
}
