// ignore_for_file: avoid_print

import 'dart:io';
import 'package:path/path.dart' as p;
import "package:archive/archive.dart";
import 'package:yaml/yaml.dart';

void main() {
  print("Will build dist for windows and publish the release...");

  // updating version tag
  final previousVersionTag = readPreviousVersion();
  print("Previous version: [$previousVersionTag]");
  var newVersionTag =
      prompt("What's the new version tag (make sure it is URL compatible, leave empty if you don't want to change)?")
          .trim();
  if (newVersionTag.isEmpty) newVersionTag = previousVersionTag;
  print("$previousVersionTag -> $newVersionTag");
  replaceVersion(previousVersionTag, newVersionTag);

  buildFor(
    flutterArg: "apk",
    platform: "android",
    resPath: p.join(Directory.current.path, "build", "app", "outputs", "flutter-apk", "app-release.apk"),
    shouldArchive: false,
    newVersionTag: newVersionTag,
    copyDirectory: false,
  );

  buildFor(
    flutterArg: "web",
    platform: "web",
    resPath: p.join(Directory.current.path, "build", "web"),
    shouldArchive: false,
    newVersionTag: newVersionTag,
    copyDirectory: true,
  );

  // updating changelog
  final changes = prompt(
          "What are the changes? (separate lines by triple forward slash ///) leave empty if you don't wish to update the changelog.")
      .split("///");
  if (changes.join("").isNotEmpty) {
    prependChangelog(newVersionTag, changes);
    print("Updated the changelog successfully");
  } else {
    print("Skipped updating the changelog");
  }
}

void buildFor(
    {required String platform,
    required String flutterArg,
    required String resPath,
    required String newVersionTag,
    required bool shouldArchive,
    required bool copyDirectory}) {
  print("building $platform...");
  final res = Process.runSync(
    Platform.isWindows ? "flutter.bat" : "flutter",
    ["build", flutterArg, "--release"],
    workingDirectory: Directory.current.path,
    environment: Platform.environment,
  );
  print("   Finished building");
  print("   Exit code: ${res.exitCode}");
  print("   Err: ${res.stderr}");
  print("   OUT: ${res.stdout}");

  // packaging
  if (shouldArchive) {
    print("Packaging for platform $platform");
    final archivePath = p.join(Directory.current.path, "dist", "shade_master.zip");
    final archive = Archive();
    addDirectoryToArchive(resPath, archive);
    final zipFile = File(archivePath);
    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);
    zipFile.writeAsBytesSync(zipData!);
    print("   Finished platform: $platform");
  } else if (copyDirectory) {
    print("Distributing for platform $platform");
    copyDirectorySync(Directory(resPath), Directory(p.join(Directory.current.path, "dist", platform)));
    print("   Finished platform: $platform");
  } else {
    print("Distributing for platform $platform");
    final extension = p.basename(resPath).split(".").last;
    File sourceFile = File(resPath);
    File destinationFile = File(p.join(Directory.current.path, "release", "shade_master.$extension"));
    destinationFile.writeAsBytesSync(sourceFile.readAsBytesSync());
    print("   Finished platform: $platform");
  }
}

void copyDirectorySync(Directory source, Directory destination) {
  if (!source.existsSync()) {
    throw Exception("Source directory does not exist: ${source.path}");
  }

  // Create the destination directory if it doesn't exist
  if (!destination.existsSync()) {
    destination.createSync(recursive: true);
  }

  // Copy each entity from the source directory to the destination
  for (var entity in source.listSync()) {
    final newPath = p.join(destination.path, p.basename(entity.path));
    if (entity is File) {
      entity.copySync(newPath);
    } else if (entity is Directory) {
      copyDirectorySync(entity, Directory(newPath));
    }
  }
}

void addDirectoryToArchive(String directoryPath, Archive archive) {
  final directory = Directory(directoryPath);

  if (!directory.existsSync()) {
    throw Exception("Directory does not exist: $directoryPath");
  }

  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File) {
      final file = entity;
      final fileContent = file.readAsBytesSync();

      final relativePath = file.path.substring(directory.path.length + 1);

      archive.addFile(ArchiveFile(relativePath, fileContent.length, fileContent));
    }
  }
}

String readPreviousVersion() {
  final fileContents = File("pubspec.yaml").readAsStringSync();
  final yamlMap = loadYaml(fileContents) as YamlMap;
  return yamlMap["version"] as String;
}

void replaceVersion(String oldV, String newV) {
  final file1 = File("pubspec.yaml");
  final content1 = file1.readAsStringSync().replaceAll("version: $oldV", "version: $newV");
  file1.writeAsStringSync(content1);
  final file2 = File("./lib/version.dart");
  final content2 = file2.readAsStringSync().replaceAll(oldV, newV);
  file2.writeAsStringSync(content2);
}

String prompt(String message) {
  print("$message\n>");
  return stdin.readLineSync()!;
}

void prependChangelog(String versionTag, List<String> changes) {
  final file = File("CHANGELOG.md");
  final changesStr = "\n-   ${changes.join("\n-   ")}";
  final content = file.readAsStringSync();
  final newContent = "\n### ____${versionTag}____\n$changesStr\n\n$content";
  file.writeAsStringSync(newContent);
}
