import 'dart:io';
import 'package:careerclaritycompanion/data_seeder/domain_detail_seeder.dart';
import 'package:careerclaritycompanion/service/clodinary_service/cloudinary_service.dart';
import 'package:careerclaritycompanion/service/seeder.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dropdown_search/dropdown_search.dart';

class DomainSeederUI extends StatefulWidget {
  const DomainSeederUI({super.key});

  @override
  State<DomainSeederUI> createState() => _DomainSeederUIState();
}

class _DomainSeederUIState extends State<DomainSeederUI> {
  final List<String> validUdemyCategories = [
    "development",
    "web_development",
    "data_science",
    "mobile_apps",
    "programming_languages",
    "game_development",
    "databases",
    "software_testing",
    "software_engineering",
    "development_tools",
    "no_code_development",
    "Business",
    "business",
    "entrepreneurship",
    "communications",
    "management",
    "sales",
    "business_strategy",
    "operations",
    "project_management",
    "business_law",
    "Finance & Accounting",
    "analytics_and_intelligence",
    "human_resources",
    "industry",
    "e_commerce",
    "media",
    "real_estate",
    "other_business",
    "finance_and_accounting",
    "accounting_bookkeeping",
    "compliance",
    "cryptocurrency_and_blockchain",
    "economics",
    "finance_management",
    "finance_certification_and_exam_prep",
    "financial_modeling_and_analysis",
    "investing_and_trading",
    "money_management_tools",
    "taxes",
    "other_finance_and_accounting",
    "IT & Software",
    "it_and_software",
    "it_certification",
    "network_and_security",
    "hardware",
    "operating_system",
    "other_it_and_software",
    "Office Productivity",
    "office_productivity",
    "microsoft",
    "apple",
    "google",
    "sap",
    "oracle",
    "other_productivity",
  ];

  String? selectedDomain;
  final _searchTermsController = TextEditingController();
  File? _pickedImage;
  bool _loading = false;

  final CloudinaryService _cloudinaryService = CloudinaryService();
  final SeederService _seederService = SeederService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _seedDomain() async {
    final searchTerms = _searchTermsController.text.trim();

    if (selectedDomain == null) {
      Fluttertoast.showToast(msg: "Select a valid domain");
      return;
    }

    if (_pickedImage == null) {
      Fluttertoast.showToast(msg: "Pick an image");
      return;
    }

    setState(() => _loading = true);

    try {
      // 1️⃣ Upload image to Cloudinary
      final imageUrl = await _cloudinaryService.uploadImage(_pickedImage!);
      if (imageUrl == null) throw Exception("Image upload failed");

      // 2️⃣ Seed domain details (AI-generated)
      await DomainSeeder().seedDomains(selectedDomain!);

      // 3️⃣ Update domain image in Firestore
      final domainRef = _firestore.collection("domains").doc(selectedDomain);
      await domainRef.set({"domainImgUrl": imageUrl}, SetOptions(merge: true));

      Fluttertoast.showToast(msg: "Domain image uploaded");

      // 4️⃣ Seed courses & internships for each search term
      final termsList = searchTerms.split(',').map((e) => e.trim()).toList();

      for (final term in termsList) {
        await _seederService.seedUdemyCourses(mainDomain: selectedDomain!);
        await _seederService.seedInternships(
          mainDomain: selectedDomain!,
          searchTerm: term,
        );
      }

      Fluttertoast.showToast(msg: "Seeding completed successfully ✅");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _searchTermsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Domain Seeder")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // CORRECTED DROPDOWN WIDGET
              DropdownSearch<String>(
                selectedItem: selectedDomain,

                // For dynamic search filtering
                items: (filter, _) async {
                  // return filtered list
                  return validUdemyCategories
                      .where(
                        (e) => e.toLowerCase().contains(filter.toLowerCase()),
                      )
                      .toList();
                },

                onChanged: (value) {
                  selectedDomain = value;
                },

                // How the dropdown looks
                decoratorProps: DropDownDecoratorProps(
                  decoration: InputDecoration(
                    labelText: "Select Domain",
                    border: OutlineInputBorder(),
                  ),
                ),

                // Popup & search
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
              const SizedBox(height: 16),

              TextField(
                controller: _searchTermsController,
                decoration: const InputDecoration(
                  labelText: "Search Terms (comma-separated)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              _pickedImage != null
                  ? Image.file(_pickedImage!, height: 150, fit: BoxFit.cover)
                  : Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 80),
                  ),
              const SizedBox(height: 8),

              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text("Pick Domain Image"),
              ),
              const SizedBox(height: 24),

              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _seedDomain,
                    child: const Text("Seed Domain Data"),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
