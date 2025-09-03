import 'package:careerclaritycompanion/features/custom_widgets/fllutter_toast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RegisterCollegePage extends StatefulWidget {
  const RegisterCollegePage({super.key});

  @override
  State<RegisterCollegePage> createState() => _RegisterCollegePageState();
}

class _RegisterCollegePageState extends State<RegisterCollegePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _domainController = TextEditingController();

  bool _isLoading = false;

  Future<void> _registerCollege() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text.trim();
      final domain = _domainController.text.trim().toLowerCase();

      // 🔎 Check if domain already exists
      final existing =
          await FirebaseFirestore.instance
              .collection("colleges")
              .where("domain", isEqualTo: domain)
              .get();

      if (existing.docs.isNotEmpty) {
        showBottomToast(
          "This college domain is already registered!",
          bg: Colors.orange,
        );
        setState(() => _isLoading = false);
        return;
      }

      // ✅ Add new college
      await FirebaseFirestore.instance.collection("colleges").add({
        "name": name,
        "domain": domain,

        "createdAt": FieldValue.serverTimestamp(),
      });

      showBottomToast("College registered successfully!", bg: Colors.green);

      _nameController.clear();
      _domainController.clear();
    } catch (e) {
      showBottomToast("Error: $e", bg: Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register College")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "College/University Name",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty ? "Enter a name" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _domainController,
                decoration: const InputDecoration(
                  labelText: "College Email Domain (e.g., aalimec.ac.in)",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter a domain";
                  }
                  if (!value.contains(".")) {
                    return "Enter a valid domain";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerCollege,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                        : const Text("Register College"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
