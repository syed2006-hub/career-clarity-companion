import 'package:careerclaritycompanion/features/screens/profile/other_user_profile.dart';
import 'package:careerclaritycompanion/features/screens/profile/profile_screens.dart';
import 'package:careerclaritycompanion/service/provider/department_provider.dart';
import 'package:careerclaritycompanion/service/provider/domain_provider.dart';
import 'package:careerclaritycompanion/service/provider/leaderboard_provider.dart'; // Your provider file
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math'; // Import for math functions

// NOTE: Your StateNotifier and other providers remain unchanged.

final leaderboardFilterProvider =
    StateNotifierProvider<LeaderboardFilterNotifier, LeaderboardFilter>((ref) {
      return LeaderboardFilterNotifier();
    });

class LeaderboardFilterNotifier extends StateNotifier<LeaderboardFilter> {
  LeaderboardFilterNotifier()
    : super(
        LeaderboardFilter(
          year: '',
          collegeId: '',
          fieldOfStudy: '',
          selectedTabIndex: 0,
        ),
      );

  void setFilter(LeaderboardFilter filter) {
    state = filter;
  }
}

class LeaderboardScreen extends ConsumerStatefulWidget {
  final String? flag; // Nullable

  const LeaderboardScreen({this.flag, super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

// ✨ ADDED SingleTickerProviderStateMixin for custom animations
class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedCollege;
  String? _selectedDepartment;
  String? _selectedYear;
  String? _selectedDomain; // <-- ADD THIS
  final List<String> _yearOptions = [
    'All Years',
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
  ];

  // ✨ Animation Controller and Animations
  late AnimationController _controller;
  late Animation<double> _podiumRevealAnimation;
  late Animation<double> _firstPlaceAnimation;
  late Animation<double> _secondPlaceAnimation;
  late Animation<double> _thirdPlaceAnimation;

  @override
  void initState() {
    super.initState();
    // ✨ Initialize the Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2000,
      ), // Total duration for the sequence
    );

    // ✨ Define the animation sequence using Intervals
    _podiumRevealAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _firstPlaceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.elasticOut),
      ),
    );
    _secondPlaceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.85, curve: Curves.elasticOut),
      ),
    );
    _thirdPlaceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // ✨ Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDetailsAsync = ref.watch(userDetailsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1E212A),
      body: userDetailsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: Colors.red),
              ),
            ),
        data: (userDetails) {
          if (_selectedCollege == null &&
              userDetails['collegeId']!.isNotEmpty) {
            _selectedCollege = userDetails['collegeId'];
            _selectedDepartment = 'All Departments';
            _selectedYear = 'All Years';

            WidgetsBinding.instance.addPostFrameCallback((_) {
              final initialFilter = LeaderboardFilter(
                collegeId: _selectedCollege!,
                fieldOfStudy: _selectedDepartment!,
                year: _selectedYear!,
                selectedTabIndex: 0,
              );
              ref
                  .read(leaderboardFilterProvider.notifier)
                  .setFilter(initialFilter);
            });
          }

          final currentFilter = ref.watch(leaderboardFilterProvider);
          final leaderboardAsync = ref.watch(
            leaderboardProvider(currentFilter),
          );
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      if (widget.flag !=
                          'college') // Only show back button if flag is NOT "college"
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      const Spacer(flex: 2),
                      Text(
                        "Student Leaderboard",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(flex: 3),
                    ],
                  ),
                ),

                _buildFilterSection(userDetails),
                Expanded(
                  child: leaderboardAsync.when(
                    loading:
                        () => const Center(child: CircularProgressIndicator()),
                    error:
                        (e, _) => Center(
                          child: Text(
                            'Error: $e',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                    data: (entries) {
                      // ✨ Start the animation sequence when data is loaded
                      if (!_controller.isAnimating) {
                        _controller.forward(from: 0.0);
                      }

                      if (entries.isEmpty) {
                        return Center(
                          child: Text(
                            "No rankings available yet.",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        );
                      }

                      final top3 = entries.take(3).toList();
                      final rest = entries.skip(3).toList();

                      return AnimationLimiter(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _buildPodium(top3),
                            // The "Ranked" title and list items below will still use the staggered animation
                            AnimationConfiguration.staggeredList(
                              position: 1,
                              duration: const Duration(milliseconds: 500),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: _buildRankedListTitle(),
                                ),
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: rest.length,
                              itemBuilder: (context, index) {
                                final entry = rest[index];
                                final rank = index + 4;
                                final isCurrentUser = entry.id == currentUserId;

                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 375),
                                  child: SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(
                                      child: _buildRankedListItem(
                                        entry,
                                        rank,
                                        isCurrentUser,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- Filter Section remains unchanged ---
  Widget _buildFilterSection(Map<String, String> userDetails) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Consumer(
        builder: (context, ref, _) {
          // Fetch departments for selected college
          final deptAsync = ref.watch(
            departmentsProvider(_selectedCollege ?? ''),
          );

          // Fetch available domains
          final domainAsync = ref.watch(domainNamesProvider);

          return deptAsync.when(
            loading: () => const CircularProgressIndicator(strokeWidth: 2),
            error:
                (e, _) => Text(
                  'Error: $e',
                  style: const TextStyle(color: Colors.red),
                ),
            data: (departmentOptions) {
              _selectedDepartment ??=
                  departmentOptions.isNotEmpty ? departmentOptions.first : null;
              _selectedYear ??= _yearOptions.first;

              return domainAsync.when(
                loading: () => const CircularProgressIndicator(strokeWidth: 2),
                error:
                    (e, _) => Text(
                      'Error: $e',
                      style: const TextStyle(color: Colors.red),
                    ),
                data: (domainOptions) {
                  // Add 'All Domains' option at the top
                  final domainList =
                      ['All Domains'] +
                      domainOptions.map((d) => d.name).toList();
                  _selectedDomain ??= 'All Domains';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Department and Year Row ---
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: _buildDropdown(
                              "Department",
                              _selectedDepartment,
                              departmentOptions,
                              (newValue) {
                                setState(() {
                                  _selectedDepartment = newValue;
                                  final newFilter = LeaderboardFilter(
                                    collegeId: _selectedCollege!,
                                    fieldOfStudy: _selectedDepartment!,
                                    year: _selectedYear!,
                                    domain: _selectedDomain!,
                                    selectedTabIndex:
                                        (_selectedDepartment ==
                                                'All Departments')
                                            ? 0
                                            : 1,
                                  );
                                  ref
                                      .read(leaderboardFilterProvider.notifier)
                                      .setFilter(newFilter);
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _buildDropdown(
                              "Year",
                              _selectedYear,
                              _yearOptions,
                              (newValue) {
                                setState(() {
                                  _selectedYear = newValue;
                                  final newFilter = LeaderboardFilter(
                                    collegeId: _selectedCollege!,
                                    fieldOfStudy: _selectedDepartment!,
                                    year: _selectedYear!,
                                    domain: _selectedDomain!,
                                    selectedTabIndex:
                                        (_selectedDepartment ==
                                                'All Departments')
                                            ? 0
                                            : 1,
                                  );
                                  ref
                                      .read(leaderboardFilterProvider.notifier)
                                      .setFilter(newFilter);
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // --- Domain Dropdown Below ---
                      _buildDropdown("Domain", _selectedDomain, domainList, (
                        newValue,
                      ) {
                        setState(() {
                          _selectedDomain = newValue;
                          final newFilter = LeaderboardFilter(
                            collegeId: _selectedCollege!,
                            fieldOfStudy: _selectedDepartment!,
                            year: _selectedYear!,
                            domain: _selectedDomain!,
                            selectedTabIndex:
                                (_selectedDepartment == 'All Departments')
                                    ? 0
                                    : 1,
                          );
                          ref
                              .read(leaderboardFilterProvider.notifier)
                              .setFilter(newFilter);
                        });
                      }),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDropdown(
    String hint,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2C313C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          dropdownColor: const Color(0xFF2C313C),
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
          hint: Text(hint, style: GoogleFonts.poppins(color: Colors.white70)),
          items:
              items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // --- Podium build methods are now connected to the Animation Controller ---
  Widget _buildPodium(List<LeaderboardEntry> top3) {
    final secondPlace = top3.length > 1 ? top3[1] : null;
    final firstPlace = top3.isNotEmpty ? top3[0] : null;
    final thirdPlace = top3.length > 2 ? top3[2] : null;

    return AnimatedBuilder(
      animation: _podiumRevealAnimation,
      builder: (context, child) {
        return ClipPath(
          clipper: CircleRevealClipper(_podiumRevealAnimation.value),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, 1),
            radius: 1.2,
            colors: [Colors.amber.withOpacity(0.4), Colors.transparent],
            stops: const [0.0, 1.0],
            focal: const Alignment(0, 1),
            focalRadius: 0.4,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildPodiumMember(secondPlace, 2, _secondPlaceAnimation),
            const SizedBox(width: 10),
            _buildPodiumMember(firstPlace, 1, _firstPlaceAnimation),
            const SizedBox(width: 10),
            _buildPodiumMember(thirdPlace, 3, _thirdPlaceAnimation),
          ],
        ),
      ),
    );
  }

  // ✨ Added GestureDetector around podium member
  Widget _buildPodiumMember(
    LeaderboardEntry? entry,
    int rank,
    Animation<double> animation,
  ) {
    final double height = rank == 1 ? 90 : (rank == 2 ? 60 : 40);
    final double avatarRadius = rank == 1 ? 40 : 30;

    return Expanded(
      child: ScaleTransition(
        scale: animation,
        child: FadeTransition(
          opacity: animation,
          child: GestureDetector(
            onTap: () {
              if (entry != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(uid: entry.id),
                  ),
                );
              }
            },
            child: Column(
              children: [
                if (entry != null) ...[
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage:
                            entry.photoUrl.isNotEmpty
                                ? NetworkImage(entry.photoUrl)
                                : null,
                        child:
                            entry.photoUrl.isEmpty
                                ? Icon(Icons.person, size: avatarRadius)
                                : null,
                      ),
                      if (rank == 1)
                        Positioned(
                          top: -20,
                          left: 0,
                          right: 0,
                          child: Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 40,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.name.split(' ').first,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${entry.points} Points',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E212A),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Ranked List and Item methods remain unchanged ---
  Widget _buildRankedListTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Text(
        "Ranked",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRankedListItem(
    LeaderboardEntry entry,
    int rank,
    bool isCurrentUser,
  ) {
    return GestureDetector(
      onTap: () {
        print(entry.id);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(uid: entry.id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              isCurrentUser
                  ? Colors.indigo.withOpacity(0.5)
                  : const Color(0xFF2C313C),
          borderRadius: BorderRadius.circular(12),
          border:
              isCurrentUser
                  ? Border.all(color: Colors.cyanAccent, width: 1.5)
                  : null,
        ),
        child: Row(
          children: [
            Text(
              '$rank',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 16),
            CircleAvatar(
              radius: 22,
              backgroundImage:
                  entry.photoUrl.isNotEmpty
                      ? NetworkImage(entry.photoUrl)
                      : null,
              child: entry.photoUrl.isEmpty ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: GoogleFonts.poppins(
                      color: isCurrentUser ? Colors.cyanAccent : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Total Points',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${entry.points}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✨ Custom Clipper for the circular reveal "rounding" animation
class CircleRevealClipper extends CustomClipper<Path> {
  final double revealPercent;

  CircleRevealClipper(this.revealPercent);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = sqrt(pow(size.width / 2, 2) + pow(size.height / 2, 2));
    final radius = maxRadius * revealPercent;

    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
