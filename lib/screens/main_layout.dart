import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../constants/app_design.dart';
import 'home_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';
import 'refer_screen.dart';
import 'extra_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    HomeScreen(),
    ReferScreen(),
    ExtraScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  void _go(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _RupiNavBar(
        currentIndex: _currentIndex,
        onTap: _go,
      ),
    );
  }
}

/// Fresh floating pill navigation: a detached, rounded glass bar with a pill
/// indicator behind the active tab and a raised gradient "Earn" action.
class _RupiNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _RupiNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppDesign.brPillFor(70),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.16),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(0, Icons.home_rounded, 'Home'),
            _item(1, Icons.card_giftcard_rounded, 'Refer'),
            _centerAction(),
            _item(3, Icons.account_balance_wallet_rounded, 'Wallet'),
            _item(4, Icons.person_rounded, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _item(int index, IconData icon, String label) {
    final active = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: AppDesign.med,
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryFixed : Colors.transparent,
            borderRadius: AppDesign.brPillFor(46),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 22,
                  color: active ? AppColors.primary : AppColors.outline),
              if (active) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _centerAction() {
    final active = currentIndex == 2;
    return GestureDetector(
      onTap: () => onTap(2),
      child: Container(
        width: 58,
        height: 58,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.goldGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.coinGoldDeep.withValues(alpha: active ? 0.55 : 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Center(
          child: Icon(Icons.bolt_rounded, color: Color(0xFF7A5300), size: 28),
        ),
      ),
    );
  }
}
