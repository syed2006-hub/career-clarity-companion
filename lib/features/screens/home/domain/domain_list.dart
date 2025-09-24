import 'package:careerclaritycompanion/data/models/doamin_model.dart';
import 'package:careerclaritycompanion/features/screens/home/domain/domain_detail_screen.dart';
import 'package:careerclaritycompanion/service/provider/domain_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class DomainListScreen extends ConsumerWidget {
  final bool showAll;
  const DomainListScreen({super.key, this.showAll = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domainsAsync = ref.watch(domainNamesProvider);

    return domainsAsync.when(
      data: (domains) {
        if (domains.isEmpty) {
          return const Center(
            child: Text(
              "No domains available",
              style: TextStyle(color: Colors.white70),
            ),
          );
        }
        final itemCount =
            showAll
                ? domains.length
                : (domains.length > 4 ? 4 : domains.length);

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final domain = domains[index];

            return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  // ✨ 1. Pass the 'showAll' property to the card
                  child: _DomainCard(domain: domain, showAll: showAll),
                )
                .animate()
                .fadeIn(duration: 500.ms, delay: (100 * index).ms)
                .slide(begin: const Offset(0, 0.2), curve: Curves.easeOut);
          },
        );
      },
      loading:
          () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      error:
          (err, _) => Center(
            child: Text(
              "Error: $err",
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
    );
  }
}

class _DomainCard extends StatelessWidget {
  final DomainModel domain;
  // ✨ 2. Accept the 'showAll' property
  final bool showAll;
  const _DomainCard({required this.domain, required this.showAll});

  @override
  Widget build(BuildContext context) {
    // ✨ 3. Define colors conditionally based on 'showAll'
    final Color cardColor =
        showAll ? Colors.white : Colors.white.withOpacity(0.1);
    final Color borderColor =
        showAll ? Colors.grey.shade200 : Colors.white.withOpacity(0.2);
    final Color primaryTextColor = showAll ? Colors.black : Colors.white;
    final Color secondaryTextColor =
        showAll ? Colors.black.withOpacity(0.7) : Colors.white70;
    final Color iconColor =
        showAll ? Colors.black.withOpacity(0.6) : Colors.white70;

    return InkWell(
      onTap:
          () => Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => DomainDetailScreen(domainId: domain.name),
            ),
          ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // ✨ 4. Apply the conditional card and border colors
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                domain.domainImgUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.white.withOpacity(0.1),
                      child: const Icon(Icons.category, color: Colors.white70),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    domain.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      // ✨ 5. Apply the conditional primary text color
                      color: primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    domain.intro,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      // ✨ 6. Apply the conditional secondary text color
                      color: secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ✨ 7. Apply the conditional icon color
            Icon(Icons.arrow_forward_ios_sharp, color: iconColor, size: 18),
          ],
        ),
      ),
    );
  }
}
