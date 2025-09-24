import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class CareerShimmerPageNoIcons extends StatelessWidget {
  const CareerShimmerPageNoIcons({super.key});

  // Helper method for creating a shimmer placeholder box
  Widget _buildPlaceholder({
    double? width,
    double? height,
    bool isCircle = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black, // This color is necessary for shimmer to work
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(8.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[700]!,
        child: SafeArea(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildGuidanceCard(),
              const SizedBox(height: 24),
              _buildSectionTitle(),
              const SizedBox(height: 16),
              _buildRecommendationsList(),
              const SizedBox(height: 24),
              _buildSectionTitle(),
              const SizedBox(height: 16),
              _buildTopCompaniesList(),
            ],
          ),
        ),
      ),
    );
  }

  // Mimics the header (Menu icon placeholder is REMOVED)
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPlaceholder(width: 120, height: 16),
            const SizedBox(height: 8),
            _buildPlaceholder(width: 150, height: 12),
          ],
        ),
        _buildPlaceholder(width: 48, height: 48, isCircle: true),
      ],
    );
  }

  // Mimics the "Ask Career Guidance" card
  Widget _buildGuidanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildPlaceholder(width: 60, height: 60),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPlaceholder(width: double.infinity, height: 20),
                const SizedBox(height: 10),
                _buildPlaceholder(width: 100, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mimics a section title like "Smart Recommendations"
  Widget _buildSectionTitle() {
    return _buildPlaceholder(width: 200, height: 20);
  }

  // Mimics the horizontally scrolling list of recommendation cards
  Widget _buildRecommendationsList() {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => _buildShimmerCard(),
      ),
    );
  }

  // Mimics a single recommendation card
  Widget _buildShimmerCard() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPlaceholder(
                width: 40,
                height: 40,
                isCircle: true,
              ), // Company logo placeholder
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPlaceholder(width: 180, height: 16),
                  const SizedBox(height: 8),
                  _buildPlaceholder(width: 120, height: 12),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // MODIFIED: Only show text placeholder, no icon placeholder
          _buildPlaceholder(width: 150, height: 12),
          const SizedBox(height: 8),
          // MODIFIED: Only show text placeholder, no icon placeholder
          _buildPlaceholder(width: 150, height: 12),
          const Spacer(),
          _buildPlaceholder(width: double.infinity, height: 45),
        ],
      ),
    );
  }

  // Mimics the horizontally scrolling list of top company logos
  Widget _buildTopCompaniesList() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 24.0),
            child: Column(
              children: [
                _buildPlaceholder(
                  width: 60,
                  height: 60,
                  isCircle: true,
                ), // Company logo
                const SizedBox(height: 8),
                _buildPlaceholder(width: 80, height: 12), // Company name
              ],
            ),
          );
        },
      ),
    );
  }
}
