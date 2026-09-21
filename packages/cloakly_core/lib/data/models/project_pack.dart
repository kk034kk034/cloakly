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

class ProjectTask {
  const ProjectTask({
    required this.id,
    required this.title,
    required this.status,
    required this.updatedAt,
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
  final DateTime? startDate;
  final DateTime? endDate;
  final String owner;
  final List<String> sources;
  final bool confirmed;

  ProjectTask copyWith({
    String? title,
    ProjectTaskStatus? status,
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

  List<KnowledgeDoc> get includedDocs =>
      docs.where((doc) => doc.included).toList();

  int get includedCount => includedDocs.length;

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
  }) {
    return ProjectPack(
      personalContext: personalContext ?? this.personalContext,
      transcriptionTerms: transcriptionTerms ?? this.transcriptionTerms,
      tasks: tasks ?? this.tasks,
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
  };

  factory ProjectPack.fromJson(Map<String, dynamic> json) {
    final rawDocs = json['docs'] as List<dynamic>? ?? const [];
    final folderPath = json['folderPath']! as String;
    return ProjectPack(
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
    );
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
