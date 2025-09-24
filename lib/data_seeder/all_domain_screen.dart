import 'package:careerclaritycompanion/features/screens/home/domain/domain_list.dart';
import 'package:flutter/material.dart';

class AllDomainScreen extends StatelessWidget {
  const AllDomainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Domains"),
        centerTitle: true, 
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: DomainListScreen(showAll: true),
        ), // 👈 show all domains
      ),
    );
  }
}
