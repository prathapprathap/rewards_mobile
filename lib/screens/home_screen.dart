import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'offer_detail_screen.dart';
import 'offerwall_screen.dart';
import 'refer_screen.dart';
import '../providers/settings_provider.dart';
import '../widgets/wallet_symbol_icon.dart';
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
      'subtitle': 'REFER AND\nEARN',
      'action': 'INVITE FRIENDS NOW! ✦',
      'type': 'refer',
      'image_url': null,
      'color1': const Color(0xFF6A11CB),
      'color2': const Color(0xFF2575FC),
      'icon': Icons.share_rounded,
    },
    {
      'title': 'OFFERS',
      'subtitle': 'TASK AND\nEARN',
      'action': 'START EARNING NOW! ✦',
      'type': 'offers',
      'image_url': null,
      'color1': const Color(0xFF00B4DB),
      'color2': const Color(0xFF0083B0),
      'icon': Icons.card_giftcard,
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
      final banners = await api.getBanners();
      if (mounted && banners.isNotEmpty) {
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
                  : 'OPEN NOW! ✦',
              'type': 'url',
              'value': rawValue,
              'image_url': b['image_url'],
              'color1': const Color(0xFF6A11CB),
              'color2': const Color(0xFF2575FC),
              'icon': Icons.open_in_new_rounded,
            };
          }).toList();
        });
      }
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
      final offers = await api.getUserOffers(userId);
      if (mounted) {
        setState(() {
          _offers = offers;
          _isLoading = false;
        });
      }
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(user),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildHeroCarousel(),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('DAILY TASKS'),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OfferwallScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'VIEW ALL',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDailyTasksList(),
                        const SizedBox(height: 100), // Bottom padding for FAB
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  SliverAppBar _buildSliverAppBar(dynamic user) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo.png',
              height: 24,
              errorBuilder: (c, e, s) =>
                  Icon(Icons.eco, color: AppColors.primary, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'RUPI REWARDS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: 0.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [_buildWalletPill(user), const SizedBox(width: 16)],
    );
  }

  Widget _buildWalletPill(dynamic user) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WalletSymbolIcon(size: 20),
          const SizedBox(width: 8),
          Text(
            (user?.walletBalance ?? 0.00).toStringAsFixed(2),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCarousel() {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemCount: _banners.length,
        itemBuilder: (context, index) {
          final banner = _banners[index];
          return _buildBannerItem(banner);
        },
      ),
    );
  }

  Widget _buildBannerItem(Map<String, dynamic> banner) {
    return GestureDetector(
      onTap: () => _handleBannerClick(banner),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [banner['color1'], banner['color2']],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: banner['color2'].withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (banner['image_url'] != null && banner['image_url'].toString().isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.network(
                    banner['image_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  ),
                ),
              ),
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                banner['icon'],
                size: 140,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: banner['image_url'] != null 
                  ? LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    )
                  : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner['subtitle'],
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      banner['action'],
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 16,
              right: 24,
              child: Row(
                children: List.generate(
                  _banners.length,
                  (i) => _buildDot(i == _currentPage),
                ),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: active ? 16 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: active ? 1.0 : 0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDailyTasksList() {
    final tasks = _offers.take(5).toList();
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks available'));
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (task['image_url'] != null &&
                            task['image_url'].toString().isNotEmpty)
                        ? Image.network(
                            task['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.image_outlined),
                          )
                        : const Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task['offer_name'] ?? 'Task',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildRewardPill('+${task['amount'] ?? 0}'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          if (task['side_label'] != null && task['side_label'].toString().isNotEmpty)
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const WalletSymbolIcon(size: 16, fallbackColor: Colors.white),
          const SizedBox(width: 6),
          Text(
            amount,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
