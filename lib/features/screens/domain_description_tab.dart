import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class DomainDescriptionTab extends StatefulWidget {
  final String domainName;
  const DomainDescriptionTab({super.key, required this.domainName});

  @override
  State<DomainDescriptionTab> createState() => _DomainDescriptionTabState();
}

class _DomainDescriptionTabState extends State<DomainDescriptionTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // <-- Keeps state alive
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('domains')
              .doc(widget.domainName)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No data found'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final details = data['domainDetails'] ?? {};
        final intro = details['intro'] ?? '';
        final branches = details['branches'] ?? [];
        final expectedSalary = details['expectedSalary'] ?? {};
        final types = details['types'] ?? [];
        final futureScope = details['futureScope'] ?? '';
        final marketRate = details['marketRate'] ?? '';
        final usefulness = details['usefulness'] ?? '';
        final roadmap = details['roadmap'] ?? [];
        final imageUrl = data['domainImgUrl'] ?? '';

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header image
              imageUrl.isNotEmpty
                  ? Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  )
                  : Container(
                    width: double.infinity,
                    height: 220,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image, size: 80),
                  ),
              const SizedBox(height: 16),

              _scrollAnimated(child: _buildSection("Introduction", intro)),
              _scrollAnimated(child: _buildBranchCards("Branches", branches)),
              _scrollAnimated(
                child: _buildSalaryTable("Expected Salary", expectedSalary),
              ),
              _scrollAnimated(child: _buildCardList("Types of Work", types)),
              _scrollAnimated(
                child: _buildSection("Future Scope", futureScope),
              ),
              _scrollAnimated(
                child: _buildSection("Market Rate & Demand", marketRate),
              ),
              _scrollAnimated(
                child: _buildSection("How It Will Be Helpful", usefulness),
              ),
              _scrollAnimated(child: _buildTimelineRoadmap("Roadmap", roadmap)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  /// Wrap a section so it animates only when visible
  Widget _scrollAnimated({required Widget child}) {
    return _AnimatedOnVisible(child: child);
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildBranchCards(String title, List branches) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 12),
          ...branches.asMap().entries.map((entry) {
            int index = entry.key;
            var branch = entry.value;
            return _AnimatedOnVisible(
              delay: Duration(milliseconds: index * 150),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        branch['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (branch['focus'] != null)
                        Text(
                          "Focus: ${branch['focus']}",
                          style: const TextStyle(fontSize: 15),
                        ),
                      if (branch['technologies'] != null)
                        Text(
                          "Technologies: ${branch['technologies'].join(', ')}",
                          style: const TextStyle(fontSize: 15),
                        ),
                      if (branch['goals'] != null)
                        Text(
                          "Goal: ${branch['goals']}",
                          style: const TextStyle(fontSize: 15),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSalaryTable(String title, Map salaries) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 12),
          Table(
            border: TableBorder.all(color: Colors.grey.shade300),
            columnWidths: const {0: FlexColumnWidth(2), 1: FlexColumnWidth(3)},
            children:
                salaries.entries.map((e) {
                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          e.key,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(e.value.toString()),
                      ),
                    ],
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList(String title, List items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(item, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Timeline roadmap with individual animated cards
  Widget _buildTimelineRoadmap(String title, List roadmap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 12),
          Column(
            children: List.generate(roadmap.length, (index) {
              final milestone = roadmap[index];
              return _AnimatedOnVisible(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline dot & line
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (index != roadmap.length - 1)
                          Container(
                            width: 2,
                            height: 60,
                            color: Colors.blue.shade200,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Card for milestone
                    Expanded(
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            milestone,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _AnimatedOnVisible extends StatefulWidget {
  final Widget child;
  final Duration? delay;
  const _AnimatedOnVisible({required this.child, this.delay});

  @override
  State<_AnimatedOnVisible> createState() => _AnimatedOnVisibleState();
}

class _AnimatedOnVisibleState extends State<_AnimatedOnVisible>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: UniqueKey(),
      onVisibilityChanged: (info) {
        if (!_visible && info.visibleFraction > 0.1) {
          _visible = true;
          if (widget.delay != null) {
            Future.delayed(widget.delay!, () => _controller.forward());
          } else {
            _controller.forward();
          }
        }
      },
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(opacity: _fadeAnimation, child: widget.child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
