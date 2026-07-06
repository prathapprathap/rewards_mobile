import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/app_design.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/ui/rupi_ui.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final bool isEarnings;
  const TransactionHistoryScreen({super.key, required this.isEarnings});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  int _page = 1;
  final int _limit = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _fetchTransactions(isLoadMore: true);
      }
    }
  }

  Future<void> _fetchTransactions({bool isLoadMore = false}) async {
    if (isLoadMore) {
      _page++;
    } else {
      _page = 1;
      _isLoading = true;
      if (mounted) setState(() {});
    }

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;
      if (userId == null) return;

      final api = ApiService();
      final offset = isLoadMore ? _transactions.length : 0;
      final transactions = await api.getTransactionHistory(userId, limit: _limit, offset: offset);

      if (mounted) {
        setState(() {
          if (isLoadMore) {
            _transactions.addAll(transactions);
          } else {
            _transactions = transactions;
          }
          _isLoading = false;
          // If we received fewer than the limit, we've reached the end
          if (transactions.length < _limit) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = widget.isEarnings
        ? _transactions.where((tx) => tx['transaction_type'] != 'withdrawal').toList()
        : _transactions.where((tx) => tx['transaction_type'] == 'withdrawal').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(color: AppColors.onSurface),
        title: Text(
          widget.isEarnings ? 'Earnings History' : 'Redeem History',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTransactions,
        color: AppColors.primary,
        backgroundColor: AppColors.surfaceContainerLowest,
        child: _isLoading && _transactions.isEmpty
            ? RupiLoader.fullscreen(label: 'Loading history…')
            : filteredList.isEmpty
                ? RupiEmptyState(
                    icon: widget.isEarnings
                        ? Icons.savings_rounded
                        : Icons.receipt_long_rounded,
                    title: 'Nothing here yet',
                    subtitle: widget.isEarnings
                        ? 'Your earnings will appear here as you complete tasks.'
                        : 'Your withdrawals will appear here.',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredList.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredList.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: RupiLoader(size: 38),
                        );
                      }
                      return _buildTransactionCard(filteredList[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildTransactionCard(dynamic tx) {
    final String type = tx['transaction_type'] ?? 'reward';
    String description = tx['description'] ?? 'Activity reward';
    // Hide the referral commission percentage from users (e.g. "10% ").
    description = description.replaceAll(RegExp(r'\s*\d+(\.\d+)?%\s*'), ' ').trim();
    final double amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
    final String status = tx['status']?.toString().toLowerCase() ?? 'success';
    final String date = tx['created_at'] != null
        ? tx['created_at'].toString().substring(0, 16).replaceAll('T', ' ')
        : 'Recently';

    final bool positive = amount >= 0;
    IconData icon;
    Color iconColor = positive ? AppColors.primary : AppColors.accentPink;

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
      case 'withdrawal':
        icon = Icons.account_balance_wallet_rounded;
        break;
      case 'refund':
        icon = Icons.undo_rounded;
        iconColor = AppColors.coinGoldDeep;
        break;
      default:
        icon = Icons.bolt_rounded;
    }

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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: AppDesign.brMd,
            ),
            child: Icon(icon, color: iconColor, size: 23),
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
