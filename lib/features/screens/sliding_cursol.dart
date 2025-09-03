  import 'package:carousel_slider/carousel_slider.dart';
  import 'package:flutter/material.dart';
  import 'package:google_fonts/google_fonts.dart';

  class BannerCarousel extends StatelessWidget {
    const BannerCarousel({super.key});

    @override
    Widget build(BuildContext context) {
      final List<Widget> banners = [
        // Banner 1
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Top Course's",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Learn new skills and upgrade your career",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.work, size: 50, color: Colors.blue),
            ],
          ),
        ),

        // Banner 2
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.purple[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Top InternShips...",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Explore the most valuable interns's",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.school, size: 50, color: Colors.purple),
            ],
          ),
        ),
      ];

      return CarouselSlider(
        items: banners,
        options: CarouselOptions(
          height: 180,
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 1,
          autoPlayInterval: const Duration(seconds: 10),
        ),
      );
    }
  }
