import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  // Folder where your JSON files are stored
  final folderPath = "assets/json"; // adjust this to your path
  final outputFolder = "assets/clean"; // new folder for cleaned files

  final dir = Directory(folderPath);
  if (!await dir.exists()) {
    print("❌ Folder not found: $folderPath");
    return;
  }

  // Create output folder if it doesn’t exist
  final outDir = Directory(outputFolder);
  if (!await outDir.exists()) {
    await outDir.create(recursive: true);
    print("📁 Created folder: $outputFolder");
  }

  final files = dir.listSync().where((f) => f.path.endsWith(".json")).toList();

  print("Found ${files.length} JSON files...");

  for (final file in files) {
    final f = File(file.path);

    try {
      final content = await f.readAsString();
      final List<dynamic> data = jsonDecode(content);

      final cleanedData =
          data
              .map((item) {
                final map = Map<String, dynamic>.from(item);

                // ---- Remove invalid entries ----
                final requiredFields = [
                  "title",
                  "url",
                  "photo",
                  "rating",
                  "price",
                  "duration",
                ];
                for (final field in requiredFields) {
                  if (map[field] == null ||
                      map[field].toString().trim().toUpperCase() == "N/A") {
                    return null; // Drop this item
                  }
                }

                // ---- Fix numRatings field ----
                if (map["numRatings"] != null &&
                    map["numRatings"].toString().contains("Rating:")) {
                  final regex = RegExp(r"(\d[\d,]*)\s*ratings");
                  final match = regex.firstMatch(map["numRatings"].toString());
                  if (match != null) {
                    map["numRatings"] = "${match.group(1)} ratings";
                  } else {
                    map["numRatings"] =
                        map["numRatings"]
                            .toString()
                            .replaceAll(RegExp(r"Rating.*\n?"), "")
                            .trim();
                  }
                }

                // ---- Fix shifted values ----
                if (map["duration"].toString().contains("ratings")) {
                  final fixedNumRatings = map["duration"];
                  final fixedDuration = map["lectures"];
                  final fixedLectures = map["level"];

                  map["numRatings"] = fixedNumRatings;
                  map["duration"] = fixedDuration;
                  map["lectures"] = fixedLectures;
                  map["level"] = "All Levels"; // fallback
                }

                return map;
              })
              .where((e) => e != null)
              .toList();

      final newJson = const JsonEncoder.withIndent("  ").convert(cleanedData);

      // Save cleaned file into "assets/clean" with same filename
      final fileName = file.uri.pathSegments.last;
      final outPath = "${outDir.path}/$fileName";
      await File(outPath).writeAsString(newJson);

      print("✅ Cleaned: ${file.path} → $outPath");
    } catch (e) {
      print("❌ Error in ${file.path}: $e");
    }
  }

  print("🎉 Done cleaning all JSON files!");
}
