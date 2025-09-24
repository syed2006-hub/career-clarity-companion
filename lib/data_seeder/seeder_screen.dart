import 'package:careerclaritycompanion/data_seeder/domain_detail_seeder.dart';
import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DomainSeederUI extends StatefulWidget {
  const DomainSeederUI({super.key});

  @override
  State<DomainSeederUI> createState() => _DomainSeederUIState();
}

class _DomainSeederUIState extends State<DomainSeederUI> {
  final List<String> validDomains = [
    "mobile app development",
    "web development",
    "data science",
    "game development",
    "databases management",
    "software testing",
    "software engineering",
    "development tools",
    "no code development",
    "microsoft office",
    "operating system",
    "hardware engineering",
    "network and security",
  ];

  String? selectedDomain;
  bool _loading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DomainSeeder _domainSeeder = DomainSeeder();

  Future<void> _seedDomainAIProjects() async {
    if (selectedDomain == null) {
      Fluttertoast.showToast(msg: "Select a domain first");
      return;
    }

    setState(() => _loading = true);

    try {
      await _domainSeeder.seedDomainProjects(selectedDomain!);
      Fluttertoast.showToast(
          msg: "AI Projects & Internships seeded successfully ✅");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Domain AI Seeder")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownSearch<String>(
              selectedItem: selectedDomain,
               items: (filter, _) async {
                return validDomains
                    .where(
                      (e) => e.toLowerCase().contains(filter.toLowerCase()),
                    )
                    .toList();
              },
              onChanged: (value) => selectedDomain = value,
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  labelText: "Select Domain",
                  border: OutlineInputBorder(),
                ),
              ),
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: "Search domain...",
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _seedDomainAIProjects,
                    child: const Text("Seed Internships & AI Projects"),
                  ),
          ],
        ),
      ),
    );
  }
}
