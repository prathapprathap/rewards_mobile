import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_dialog.dart';

class DailyCheckInScreen extends StatefulWidget {
  const DailyCheckInScreen({super.key});

  @override
  State<DailyCheckInScreen> createState() => _DailyCheckInScreenState();
}

class _DailyCheckInScreenState extends State<DailyCheckInScreen> {
  bool _isLoading = false;
  int _currentDay = 2; // Dummy current day
  List<bool> _checkInHistory = List.generate(30, (index) => index < 1); // Only Day 1 done

  @override
  void initState() {
    super.initState();
    _fetchCheckInStatus();
  }

  Future<void> _fetchCheckInStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    if (userId == null) return;

    try {
      final api = ApiService();
      final data = await api.getCheckInHistory(userId);
      
      if (mounted) {
        setState(() {
          final int streak = int.tryParse(data['streak'].toString()) ?? 0;
          _currentDay = streak + 1;
          
          // Only show up to 30 days. If streak is reset, start from 1.
          _checkInHistory = List.generate(30, (index) => index < streak);
        });
      }
    } catch (e) {
      debugPrint('Error fetching check-in status: $e');
    }
  }

  Future<void> _handleCheckIn() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      final result = await api.dailyCheckIn(userId);
      
      if (mounted) {
        final reward = result['reward'] ?? 0;
        final milestone = result['milestoneReached'] ?? false;
        
        AppDialog.show(
          context,
          title: milestone ? 'Jackpot!' : 'Success',
          message: milestone 
            ? 'Amazing! You completed 30 consecutive days and earned ₹$reward!' 
            : 'You\'ve checked in for Day ${result['streak']}. Keep it up for the 30-day reward!',
          type: DialogType.success,
          onConfirm: () {
            userProvider.refreshUser();
            _fetchCheckInStatus();
          },
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialog.show(
          context,
          title: 'Error',
          message: e.toString().replaceAll('Exception: ', ''),
          type: DialogType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to SettingsProvider for dynamic color updates
    Provider.of<SettingsProvider>(context);
    final user = Provider.of<UserProvider>(context).user;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, Colors.white],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, user),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      _buildMainRewardIcon(),
                      const SizedBox(height: 24),
                      Text(
                        'Day ${_currentDay > 30 ? 30 : _currentDay}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          _currentDay >= 30 
                            ? 'CONGRATULATIONS! You have completed your 30-day streak. Claim your grand reward now!'
                            : 'Check in for 30 consecutive days to unlock the grand reward. If you miss a day, your progress resets.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildClaimButton(),
                      const SizedBox(height: 40),
                      _buildStatisticsSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.5),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Rewards',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          const Icon(Icons.card_giftcard, color: Colors.redAccent, size: 28),
          const SizedBox(width: 12),
          _buildBalancePill(user),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _buildBalancePill(dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFF1C40F),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_rupee, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Text(
             (user?.walletBalance ?? 0.0).toStringAsFixed(2),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainRewardIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer rings
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.2),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
          ),
        ),
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),
        // Central icon
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryContainer],
            ),
          ),
          child: const Icon(
            Icons.star,
            color: Color(0xFFFFD700),
            size: 80,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClaimButton() {
    final bool isMilestoneDay = (_currentDay == 30);
    
    return Container(
      width: 260,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: (isMilestoneDay ? Colors.orange : AppColors.primary).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleCheckIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: isMilestoneDay ? Colors.orange : AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
              isMilestoneDay ? 'CLAIM 30-DAY REWARD' : 'CHECK-IN DAY ${_currentDay > 30 ? 30 : _currentDay}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Statistics',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: 30,
            itemBuilder: (context, index) {
              final dayNum = index + 1;
              final isDone = _checkInHistory[index];
              return Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isDone 
                        ? const LinearGradient(
                            colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
                          )
                        : LinearGradient(
                            colors: [AppColors.primaryFixedDim, AppColors.primary],
                          ),
                      boxShadow: [
                        BoxShadow(
                          color: (isDone ? Colors.grey : AppColors.primary).withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.star,
                      color: isDone ? Colors.white70 : const Color(0xFFFFD700),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day $dayNum',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
