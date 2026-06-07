import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../constants/app_design.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'offer_detail_screen.dart';
import 'offerwall_screen.dart';
import 'refer_screen.dart';
import 'rewards_screen.dart';
import 'transaction_history_screen.dart';
import 'notifications_screen.dart';
import '../providers/settings_provider.dart';
import '../widgets/ui/rupi_ui.dart';
import '../widgets/ribbon_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _offers = [];
  bool _isLoading = true;
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _defaultBanners = [
    {
      'title': 'REF-EARN',
      'subtitle': 'Refer &\nEarn ₹₹₹',
      'action': 'INVITE FRIENDS NOW ✦',
      'type': 'refer',
      'image_url': null,
      'color1': const Color(0xFF6D34D6),
      'color2': const Color(0xFF8B5CF6),
      'icon': Icons.card_giftcard_rounded,
    },
    {
      'title': 'OFFERS',
      'subtitle': 'Complete\nTasks, Win',
      'action': 'START EARNING NOW ✦',
      'type': 'offers',
      'image_url': null,
      'color1': const Color(0xFF5126B0),
      'color2': const Color(0xFFFF5FA2),
      'icon': Icons.bolt_rounded,
    },
  ];

  List<dynamic> _banners = [];

  @override
  void initState() {
    super.initState();
    _banners = _defaultBanners; // Initialize with defaults
    _pageController = PageController(initialPage: 0);
    _fetchData();
    _fetchBanners();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _fetchBanners() async {
    try {
      final api = ApiService();
      // Cache-first: instant render from cache, then refresh in background.
      await api.getBannersCached((banners) {
        if (!mounted || banners.isEmpty) return;
        setState(() {
          _banners = banners.map((b) {
            final rawValue =
                (b['click_url'] ?? b['action_value'] ?? '').toString().trim();

            return {
              'id': b['id'],
              'subtitle': (b['subtitle'] ?? b['title'] ?? '')
                  .toString()
                  .replaceAll('\\n', '\n'),
              'action': (b['title']?.toString().trim().isNotEmpty ?? false)
                  ? b['title']
                  : 'OPEN NOW ✦',
              'type': 'url',
              'value': rawValue,
              'image_url': b['image_url'],
              'color1': const Color(0xFF6D34D6),
              'color2': const Color(0xFF8B5CF6),
              'icon': Icons.open_in_new_rounded,
            };
          }).toList();
        });
      });
    } catch (e) {
      debugPrint('Error fetching banners: $e');
    }
  }

  Future<void> _fetchData() async {
    try {
      final api = ApiService();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      // Cache-first user offers — fires the setState up to twice
      // (immediately from cache, then again after refresh).
      await api.getUserOffersCached(userId, (offers) {
        if (!mounted) return;
        setState(() {
          _offers = offers;
          _isLoading = false;
        });
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _launchOfferURL(dynamic offer) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    if (userId == null) return;
    try {
      final api = ApiService();
      final trackingData = await api.trackOfferClick(
        userId: userId,
        offerId: offer['id'] is int
            ? offer['id']
            : int.parse(offer['id'].toString()),
        deviceId: null,
      );
      final trackingUrl = trackingData['trackingUrl'];
      if (trackingUrl != null && trackingUrl.isNotEmpty) {
        final Uri uri = Uri.parse(trackingUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      // silent
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to SettingsProvider for dynamic color updates
    Provider.of<SettingsProvider>(context);
    final user = Provider.of<UserProvider>(context).user;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: RupiLoader.fullscreen(label: 'Loading your rewards…'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceContainerLowest,
        onRefresh: () async {
          await _fetchData();
          await _fetchBanners();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(user)),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -26),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildQuickActions(),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroCarousel(),
                    const SizedBox(height: 24),
                    RupiSectionHeader(
                      title: 'Daily Tasks',
                      icon: Icons.checklist_rounded,
                      actionLabel: 'View all',
                      onAction: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OfferwallScreen()),
                      ),
                    ),
                    _buildDailyTasksList(),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(dynamic user) {
    final name = (user?.name?.toString().trim().isNotEmpty ?? false)
        ? user!.name.toString().split(' ').first
        : 'there';
    return RupiHeader(
      height: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppDesign.brSm,
                ),
                child: Image.asset('assets/images/app_icon.png',
                    height: 26,
                    width: 26,
                    errorBuilder: (c, e, s) => const Text('₹',
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 20))),
              ),
              const SizedBox(width: 10),
              Text(
                'Rupi Rewards',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              RupiIconButton(
                icon: Icons.notifications_rounded,
                onHeader: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationsScreen()),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Hi $name 👋',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your balance',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  Text(
                    '₹${(user?.walletBalance ?? 0.00).toStringAsFixed(2)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _withdrawChip(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _withdrawChip() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => const TransactionHistoryScreen(isEarnings: true)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppColors.goldGradient,
          borderRadius: AppDesign.brPillFor(40),
          boxShadow: [
            BoxShadow(
              color: AppColors.coinGoldDeep.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded,
                size: 16, color: Color(0xFF5A3D00)),
            const SizedBox(width: 6),
            Text(
              'History',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF5A3D00),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction('Offers', Icons.bolt_rounded, AppColors.primary,
          () => const OfferwallScreen()),
      _QuickAction('Refer', Icons.card_giftcard_rounded, AppColors.accentPink,
          () => const ReferScreen()),
      _QuickAction('Rewards', Icons.workspace_premium_rounded,
          AppColors.coinGoldDeep, () => const RewardsScreen()),
      _QuickAction('History', Icons.receipt_long_rounded, AppColors.accentTeal,
          () => const TransactionHistoryScreen(isEarnings: true)),
    ];
    return RupiCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((a) {
          return Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => a.builder()),
              ),
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: a.color.withValues(alpha: 0.12),
                      borderRadius: AppDesign.brMd,
                    ),
                    child: Icon(a.icon, color: a.color, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return _buildBannerItem(banner);
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => _buildDot(i == _currentPage),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerItem(Map<String, dynamic> banner) {
    return GestureDetector(
      onTap: () => _handleBannerClick(banner),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: AppDesign.brLg,
          gradient: LinearGradient(
            colors: [banner['color1'], banner['color2']],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: banner['color2'].withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (banner['image_url'] != null &&
                banner['image_url'].toString().isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: AppDesign.brLg,
                  child: Image.network(
                    banner['image_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            Positioned(
              right: -16,
              bottom: -16,
              child: Icon(
                banner['icon'],
                size: 130,
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: AppDesign.brLg,
                gradient: banner['image_url'] != null
                    ? LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      )
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner['subtitle'],
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppDesign.brPillFor(30),
                    ),
                    child: Text(
                      banner['action'],
                      style: GoogleFonts.plusJakartaSans(
                        color: banner['color1'],
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBannerClick(Map<String, dynamic> banner) async {
    final type = banner['type']?.toString().toLowerCase();
    final value = banner['value']?.toString().trim();

    switch (type) {
      case 'refer':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ReferScreen()),
        );
        break;
      case 'offers':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OfferwallScreen()),
        );
        break;
      case 'url':
        if (value != null && value.isNotEmpty) {
          final uri = Uri.parse(value);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        break;
    }
  }

  Widget _buildDot(bool active) {
    return AnimatedContainer(
      duration: AppDesign.med,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.primaryFixedDim,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildDailyTasksList() {
    final tasks = _offers.take(5).toList();
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: RupiCard(
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: AppDesign.brMd,
                ),
                child: Icon(Icons.task_alt_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'No tasks right now — check back soon for fresh ways to earn!',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: tasks.map((task) => _buildTaskItem(task)).toList());
  }

  Widget _buildTaskItem(dynamic task) {
    return GestureDetector(
      onTap: () {
        final offerId = task['id'] is int
            ? task['id']
            : int.tryParse(task['id']?.toString() ?? '0');
        if (offerId != null && offerId != 0) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OfferDetailScreen(offerId: offerId),
            ),
          ).then((_) => _fetchData());
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppDesign.brLg,
              boxShadow: AppDesign.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    borderRadius: AppDesign.brMd,
                  ),
                  child: ClipRRect(
                    borderRadius: AppDesign.brSm,
                    child: (task['image_url'] != null &&
                            task['image_url'].toString().isNotEmpty)
                        ? Image.network(
                            task['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Icon(
                                Icons.bolt_rounded,
                                color: AppColors.primary),
                          )
                        : Icon(Icons.bolt_rounded, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['offer_name'] ?? 'Task',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _buildRewardPill('+${task['amount'] ?? 0}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          if (task['side_label'] != null &&
              task['side_label'].toString().isNotEmpty)
            Positioned(
              top: 0,
              left: 0,
              child: RibbonBadge(
                label: task['side_label'].toString(),
                colorOverride: task['side_label_color']?.toString(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRewardPill(String amount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: AppDesign.brPillFor(26),
      ),
      child: Text(
        '₹ $amount',
        style: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF5A3D00),
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final Color color;
  final Widget Function() builder;
  _QuickAction(this.label, this.icon, this.color, this.builder);
}
