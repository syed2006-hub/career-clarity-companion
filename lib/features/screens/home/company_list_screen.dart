import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:careerclaritycompanion/data/models/company_model.dart';

class CompanyTicker extends StatefulWidget {
  final List<CompanyInfo> companies;

  const CompanyTicker({super.key, required this.companies});

  @override
  State<CompanyTicker> createState() => _CompanyTickerState();
}

class _CompanyTickerState extends State<CompanyTicker> {
  final ScrollController _scrollController = ScrollController();
  late List<CompanyInfo> filteredCompanies;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    filteredCompanies = widget.companies.where((c) => c.rating >= 3.5).toList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startAutoScroll();
      }
    });
  }

  void _startAutoScroll() {
    const duration = Duration(milliseconds: 30); // Speed of scroll
    _timer = Timer.periodic(duration, (timer) {
      if (_scrollController.hasClients &&
          !_scrollController.position.isScrollingNotifier.value) {
        double maxScroll = _scrollController.position.maxScrollExtent;
        double currentScroll = _scrollController.offset;
        double nextScroll = currentScroll + 1;

        if (nextScroll >= maxScroll) {
          _scrollController.jumpTo(0); // Reset to start
        } else {
          _scrollController.jumpTo(nextScroll);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (filteredCompanies.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Text(
            "No high-rated companies available.",
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
        ),
      );
    }

    final displayList = [...filteredCompanies, ...filteredCompanies];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: displayList.length,
        itemBuilder: (context, index) {
          final company = displayList[index];
          return CompanyCard(
            name: company.name,
            logoUrl: company.logoUrl,
            rating: company.rating,
          );
        },
      ),
    );
  }
}

class CompanyCard extends StatelessWidget {
  final String name;
  final String logoUrl;
  final double rating;

  const CompanyCard({
    super.key,
    required this.name,
    required this.logoUrl,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          logoUrl.isNotEmpty
              ? Image.network(
                logoUrl,
                height: 40,
                width: 40,
                fit: BoxFit.contain,
                errorBuilder:
                    (context, error, stackTrace) => const Icon(
                      Icons.business,
                      size: 40,
                      color: Colors.white70,
                    ),
              )
              : const Icon(Icons.business, size: 40, color: Colors.white70),
          // ✨ FIX: Reduced vertical spacing to prevent overflow
          const SizedBox(height: 4),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
