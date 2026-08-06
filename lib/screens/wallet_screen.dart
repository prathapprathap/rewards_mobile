import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/app_design.dart';
import '../providers/user_provider.dart';
import '../providers/settings_provider.dart';
import '../services/api_service.dart';
import '../widgets/ui/rupi_ui.dart';
import '../widgets/payment_method_sheet.dart';
import 'transaction_history_screen.dart';
import 'withdrawal_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _isEarningsTab = true;
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId == null) return;

      final api = ApiService();
      final transactions = await api.getTransactionHistory(userId);

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openWithdrawFlow(BuildContext context) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final upiEnabled = settings.getString('withdraw_method_upi', 'On') == 'On';
    final bankEnabled = settings.getString('withdraw_method_bank', 'On') == 'On';

    final method = await showPaymentMethodSheet(
      context,
      upiEnabled: upiEnabled,
      bankEnabled: bankEnabled,
    );
    if (method == null || !context.mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WithdrawalScreen(method: method)),
    );
    if (mounted) _fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to SettingsProvider for dynamic color updates
    Provider.of<SettingsProvider>(context);
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceContainerLowest,
        onRefresh: _fetchTransactions,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Header + overlapping content share ONE sliver so the content
            // paints on top of the header curve (not under it).
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildHeader(),
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBalanceCard(user),
                          const SizedBox(height: 24),
                          _buildTabs(),
                          const SizedBox(height: 22),
                          _buildHistoryHeader(),
                          const SizedBox(height: 12),
                          _buildTransactionsList(),
                          const SizedBox(height: 110),
                        ],
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

  Widget _buildHeader() {
    return RupiHeader(
      height: 122,
      child: Row(
        children: [
          Text(
            'My Wallet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          RupiIconButton(
            icon: Icons.receipt_long_rounded,
            onHeader: true,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TransactionHistoryScreen(isEarnings: _isEarningsTab),
              ),
            ).then((_) => _fetchTransactions()),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(dynamic user) {
    final balance = user?.walletBalance ?? 0.00;
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: AppColors.goldGradient,
        borderRadius: AppDesign.brXl,
        boxShadow: [
          BoxShadow(
            color: AppColors.coinGoldDeep.withValues(alpha: 0.4),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: Color(0xFF7A5300), size: 18),
              const SizedBox(width: 6),
              Text(
                'Available Balance',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7A5300),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '₹${balance.toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 46,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF4A3200),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _openWithdrawFlow(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 17),
              decoration: BoxDecoration(
                color: const Color(0xFF4A3200),
                borderRadius: AppDesign.brPillFor(54),
                boxShadow: AppDesign.softShadow(
                    color: Colors.black, opacity: 0.2, y: 6, blur: 14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.south_west_rounded,
                      color: Colors.white, size: 19),
                  const SizedBox(width: 8),
                  Text(
                    'Withdraw',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: AppDesign.brPillFor(56),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              'Earnings',
              _isEarningsTab,
              () => setState(() => _isEarningsTab = true),
            ),
          ),
          Expanded(
            child: _buildTabItem(
              'My Redeems',
              !_isEarningsTab,
              () => setState(() => _isEarningsTab = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDesign.fast,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: AppDesign.brPillFor(46),
          boxShadow: active ? AppDesign.softShadow(opacity: 0.08, y: 3, blur: 8) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryHeader() {
    return RupiSectionHeader(
      title: 'Recent Activity',
      actionLabel: 'View all',
      onAction: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionHistoryScreen(isEarnings: _isEarningsTab),
          ),
        ).then((_) => _fetchTransactions());
      },
    );
  }

  Widget _buildTransactionsList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: RupiLoader(size: 48),
      );
    }

    final filteredList = _isEarningsTab
        ? _transactions
            .where((tx) => tx['transaction_type'] != 'withdrawal')
            .take(5)
            .toList()
        : _transactions
            .where((tx) => tx['transaction_type'] == 'withdrawal')
            .take(5)
            .toList();

    if (filteredList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: RupiEmptyState(
          icon: _isEarningsTab
              ? Icons.savings_rounded
              : Icons.receipt_long_rounded,
          title: _isEarningsTab ? 'No earnings yet' : 'No redeems yet',
          subtitle: _isEarningsTab
              ? 'Complete tasks and refer friends to start filling your wallet.'
              : 'Your withdrawal history will show up here.',
        ),
      );
    }
    return Column(
      children: filteredList.map((tx) => _buildTransactionCard(tx)).toList(),
    );
  }

  Widget _buildTransactionCard(dynamic tx) {
    final String type = tx['transaction_type'] ?? 'reward';
    String description = tx['description'] ?? 'Activity reward';
    // Hide the referral commission percentage from users (e.g. "50% ").
    description = description.replaceAll(RegExp(r'\s*\d+(\.\d+)?%\s*'), ' ').trim();
    final double amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
    final String status = tx['status']?.toString().toLowerCase() ?? 'success';
    final String? imageUrl = tx['offer_image'];
    final String date = tx['created_at'] != null
        ? tx['created_at'].toString().substring(0, 16).replaceAll('T', ' ')
        : 'Recently';

    IconData icon;
    switch (type.toLowerCase()) {
      case 'spin':
        icon = Icons.refresh_rounded;
        break;
      case 'referral':
        icon = Icons.card_giftcard_rounded;
        break;
      case 'promo':
      case 'signup_bonus':
        icon = Icons.stars_rounded;
        break;
      case 'refund':
        icon = Icons.undo_rounded;
        break;
      case 'withdrawal':
        icon = Icons.account_balance_wallet_rounded;
        break;
      default:
        icon = Icons.bolt_rounded;
    }

    final bool positive = amount >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppDesign.brLg,
        boxShadow: AppDesign.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: (positive ? AppColors.primary : AppColors.accentPink)
                  .withValues(alpha: 0.12),
              borderRadius: AppDesign.brMd,
            ),
            child: ClipRRect(
              borderRadius: AppDesign.brMd,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Icon(icon,
                          color: positive
                              ? AppColors.primary
                              : AppColors.accentPink,
                          size: 24),
                    )
                  : Icon(icon,
                      color:
                          positive ? AppColors.primary : AppColors.accentPink,
                      size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    if (type == 'withdrawal') ...[
                      const SizedBox(width: 8),
                      _buildStatusBadge(status),
                    ]
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${positive ? '+' : ''}₹${amount.abs().toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: positive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = AppColors.coinGoldDeep;
        break;
      case 'success':
        color = AppColors.success;
        break;
      case 'rejected':
        color = AppColors.error;
        break;
      default:
        color = AppColors.outline;
    }
    return RupiChip(label: status.toUpperCase(), color: color);
  }
}
