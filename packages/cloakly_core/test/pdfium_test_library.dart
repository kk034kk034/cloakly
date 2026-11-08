import 'dart:ffi';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

/// PDFium release bundled by pdfium_dart 0.2.5 for real app builds.
///
/// `flutter test` does not run that package's native-asset hook, and it does
/// not place libpdfium next to the Flutter engine. Android, Linux, and Windows
/// app builds still download this library at build time; iOS and macOS apps
/// link the XCFramework. This helper only makes the host test process able to
/// load the same binary.
const pdfiumTestRelease = 'chromium/7811';

Future<String> ensureTestPdfiumLibrary() async {
  final override = Platform.environment['PDFIUM_PATH'];
  if (override != null && override.isNotEmpty && File(override).existsSync()) {
    return override;
  }

  final target = _targetFor(Abi.current());
  final destination = File(
    p.join(
      _packageRoot().path,
      '.dart_tool',
      'pdfium-test',
      pdfiumTestRelease.replaceAll('/', '_'),
      '${target.archivePlatform}-${target.archiveArch}',
      target.libraryFileName,
    ),
  );
  if (destination.existsSync() && destination.lengthSync() > 0) {
    return destination.path;
  }

  final archiveUri = Uri.parse(
    'https://github.com/bblanchon/pdfium-binaries/releases/download/'
    '${pdfiumTestRelease.replaceAll('/', '%2F')}/'
    'pdfium-${target.archivePlatform}-${target.archiveArch}.tgz',
  );
  // flutter test replaces dart:io HttpClient with a stub that always returns
  // 400. curl is outside that stub, so the host library can still be fetched.
  final download = File('${destination.path}.download.tgz');
  await download.parent.create(recursive: true);
  final curl = await Process.run('curl', [
    '--fail',
    '--silent',
    '--show-error',
    '--location',
    '--output',
    download.path,
    archiveUri.toString(),
  ]);
  if (curl.exitCode != 0) {
    throw StateError(
      '無法下載測試用 PDFium（curl ${curl.exitCode}）$archiveUri\n${curl.stderr}',
    );
  }
  final archive = TarDecoder().decodeBytes(
    GZipDecoder().decodeBytes(await download.readAsBytes()),
  );
  await download.delete();
  final member = archive.findFile(target.archiveLibraryPath);
  final content = member?.content;
  if (content == null || content.isEmpty) {
    throw StateError(
      'PDFium 壓縮檔沒有 ${target.archiveLibraryPath}：$archiveUri',
    );
  }
  await destination.parent.create(recursive: true);
  await destination.writeAsBytes(content, flush: true);
  return destination.path;
}

Directory _packageRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      final text = pubspec.readAsStringSync();
      if (RegExp(r'^name:\s*cloakly_core\s*$', multiLine: true).hasMatch(text)) {
        return dir;
      }
    }
    final nested = Directory(p.join(dir.path, 'packages', 'cloakly_core'));
    final nestedPubspec = File(p.join(nested.path, 'pubspec.yaml'));
    if (nestedPubspec.existsSync()) return nested;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('找不到 cloakly_core，無法放置測試用 PDFium');
}

final class _PdfiumTarget {
  const _PdfiumTarget({
    required this.archivePlatform,
    required this.archiveArch,
    required this.archiveLibraryPath,
    required this.libraryFileName,
  });

  final String archivePlatform;
  final String archiveArch;
  final String archiveLibraryPath;
  final String libraryFileName;
}

_PdfiumTarget _targetFor(Abi abi) {
  return switch (abi) {
    Abi.linuxX64 => const _PdfiumTarget(
      archivePlatform: 'linux',
      archiveArch: 'x64',
      archiveLibraryPath: 'lib/libpdfium.so',
      libraryFileName: 'libpdfium.so',
    ),
    Abi.linuxArm64 => const _PdfiumTarget(
      archivePlatform: 'linux',
      archiveArch: 'arm64',
      archiveLibraryPath: 'lib/libpdfium.so',
      libraryFileName: 'libpdfium.so',
    ),
    Abi.macosX64 => const _PdfiumTarget(
      archivePlatform: 'mac',
      archiveArch: 'x64',
      archiveLibraryPath: 'lib/libpdfium.dylib',
      libraryFileName: 'libpdfium.dylib',
    ),
    Abi.macosArm64 => const _PdfiumTarget(
      archivePlatform: 'mac',
      archiveArch: 'arm64',
      archiveLibraryPath: 'lib/libpdfium.dylib',
      libraryFileName: 'libpdfium.dylib',
    ),
    Abi.windowsX64 => const _PdfiumTarget(
      archivePlatform: 'win',
      archiveArch: 'x64',
      archiveLibraryPath: 'bin/pdfium.dll',
      libraryFileName: 'pdfium.dll',
    ),
    Abi.windowsArm64 => const _PdfiumTarget(
      archivePlatform: 'win',
      archiveArch: 'arm64',
      archiveLibraryPath: 'bin/pdfium.dll',
      libraryFileName: 'pdfium.dll',
    ),
    _ => throw UnsupportedError(
      '這個測試主機沒有對應的 PDFium 預編函式庫：$abi',
    ),
  };
}
