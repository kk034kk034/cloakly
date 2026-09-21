import 'dart:io';

import 'package:cloakly_core/data/models/project_pack.dart';
import 'package:cloakly_core/services/project/project_document_reader.dart';
import 'package:path/path.dart' as p;

class ProjectIndexer {
  static const textExtensions = {
    '.md',
    '.txt',
    '.json',
    '.yaml',
    '.yml',
    '.csv',
    '.rst',
    '.adoc',
    '.xml',
  };

  static const skipDirs = {
    '.git',
    '.svn',
    '.hg',
    '.idea',
    '.vscode',
    '.dart_tool',
    'node_modules',
    'build',
    'dist',
    'out',
    'target',
    'vendor',
    '__pycache__',
    '.next',
    'Pods',
    '.gradle',
  };

  static const skipFiles = {
    'package-lock.json',
    'yarn.lock',
    'pnpm-lock.yaml',
    'pubspec.lock',
    'cargo.lock',
    'poetry.lock',
  };

  static const maxFileBytes = 256 * 1024;
  static const maxDocs = 2000;

  Future<ProjectPack> index(String folderPath, {String? id}) async {
    final root = Directory(folderPath);
    if (!await root.exists()) {
      throw StateError('找不到資料夾：$folderPath');
    }

    final found = <KnowledgeDoc>[];
    await _walk(root, folderPath, found, 0);

    found.sort((a, b) => b.score.compareTo(a.score));
    final capped = found.take(maxDocs).toList();
    // The project folder is the source scope; all supported files participate.
    final docs = capped.map((doc) => doc.copyWith(included: true)).toList();

    return ProjectPack(
      id: id ?? '',
      folderPath: folderPath,
      name: p.basename(folderPath),
      indexedAt: DateTime.now(),
      docs: docs,
    );
  }

  Future<void> _walk(
    Directory dir,
    String rootPath,
    List<KnowledgeDoc> out,
    int depth,
  ) async {
    if (depth > 20 || out.length >= maxDocs) return;
    Stream<FileSystemEntity> listing;
    try {
      listing = dir.list(followLinks: false);
    } on FileSystemException {
      return;
    }
    await for (final entity in listing) {
      if (out.length >= maxDocs) break;
      final name = p.basename(entity.path);
      if (name.startsWith('.')) continue;
      if (entity is Directory) {
        if (skipDirs.contains(name)) continue;
        await _walk(entity, rootPath, out, depth + 1);
      } else if (entity is File) {
        if (!ProjectDocumentReader.supports(name)) continue;
        if (skipFiles.contains(name.toLowerCase())) continue;
        final stat = await entity.stat();
        if (stat.size <= 0 ||
            stat.size > ProjectDocumentReader.maxBytes(name)) {
          continue;
        }
        final relative = p.relative(entity.path, from: rootPath);
        final kind = kindFor(relative);
        out.add(
          KnowledgeDoc(
            relativePath: relative,
            kind: kind,
            byteLength: stat.size,
            included: false,
            score: scoreFor(relative, kind),
          ),
        );
      }
    }
  }

  static KnowledgeKind kindFor(String relativePath) {
    final text = relativePath.toLowerCase().replaceAll('\\', '/');
    if (_hasAny(text, const [
      '承諾',
      'commitment',
      'sla',
      'contract',
      '合約',
      'promise',
    ])) {
      return KnowledgeKind.commitment;
    }
    if (_hasAny(text, const [
      'issue',
      'bug',
      'risk',
      '風險',
      'known-issue',
      'hotfix',
    ])) {
      return KnowledgeKind.issue;
    }
    if (_hasAny(text, const ['agenda', '議程', '會議議程'])) {
      return KnowledgeKind.agenda;
    }
    if (_hasAny(text, const [
      'wbs',
      'roadmap',
      'schedule',
      'milestone',
      '時程',
      '排程',
      'gantt',
    ])) {
      return KnowledgeKind.wbs;
    }
    if (_hasAny(text, const [
      'spec',
      'api',
      'swagger',
      'openapi',
      '規格',
      'schema',
    ])) {
      return KnowledgeKind.spec;
    }
    if (_hasAny(text, const [
      'readme',
      'overview',
      'architecture',
      '背景',
      'brief',
      'project',
    ])) {
      return KnowledgeKind.background;
    }
    if (text.contains('/docs/') || text.startsWith('docs/')) {
      return KnowledgeKind.background;
    }
    return KnowledgeKind.other;
  }

  static int scoreFor(String relativePath, KnowledgeKind kind) {
    final text = relativePath.toLowerCase().replaceAll('\\', '/');
    var score = switch (kind) {
      KnowledgeKind.commitment => 100,
      KnowledgeKind.spec => 90,
      KnowledgeKind.wbs => 85,
      KnowledgeKind.issue => 80,
      KnowledgeKind.agenda => 75,
      KnowledgeKind.background => 60,
      KnowledgeKind.other => 10,
    };
    if (text.contains('readme')) score += 20;
    if (text.endsWith('.md')) score += 8;
    final depth = text.split('/').length;
    score -= (depth - 1) * 3;
    return score;
  }

  static bool _hasAny(String text, List<String> needles) {
    return needles.any(text.contains);
  }
}
