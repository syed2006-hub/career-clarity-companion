import 'package:careerclaritycompanion/data/models/doamin_model.dart';
import 'package:careerclaritycompanion/features/screens/domain_detail_screen.dart';
import 'package:careerclaritycompanion/service/provider/domain_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DomainListScreen extends ConsumerStatefulWidget {
  final bool showAll;
  const DomainListScreen({super.key, this.showAll = false});

  @override
  ConsumerState<DomainListScreen> createState() => _DomainListScreenState();
}

class _DomainListScreenState extends ConsumerState<DomainListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final domainsAsync = ref.watch(domainNamesProvider);

    return domainsAsync.when(
      data: (domains) {
        if (domains.isEmpty) {
          return const Center(child: Text("No domains available"));
        }
        final itemCount =
            widget.showAll
                ? domains.length
                : (domains.length > 4 ? 4 : domains.length);

        return ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final domain = domains[index];
            _controller.forward(); // Start animation when item appears

            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: _slideAnimation.value * 50,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DomainCard(domain: domain),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text("Error: $err")),
    );
  }
}

class _DomainCard extends StatelessWidget {
  final DomainModel domain;
  const _DomainCard({required this.domain});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () => Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => DomainDetailScreen(domainId: domain.name),
            ),
          ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                domain.domainImgUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    domain.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    domain.intro,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed:
                  () => Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder:
                          (context) =>
                              DomainDetailScreen(domainId: domain.name),
                    ),
                  ),
              icon: const Icon(Icons.arrow_forward_ios_sharp),
            ),
          ],
        ),
      ),
    );
  }
}
