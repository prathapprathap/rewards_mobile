import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<dynamic> _transactions = [];
  Map<String, dynamic> _walletBreakdown = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final api = ApiService();
      final transactions = await api.getTransactionHistory(userId);
      final walletBreakdown = await api.getWalletBreakdown(userId);

      if (mounted) {
        setState(() {
          _transactions = transactions;
          _walletBreakdown = walletBreakdown;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching transaction data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy hh:mm a').format(date);
    } catch (e) {
      return dateString;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'offer_reward':
        return Icons.card_giftcard_rounded;
      case 'referral':
        return Icons.group_add_rounded;
      case 'spin':
        return Icons.casino_rounded;
      case 'scratch':
        return Icons.touch_app_rounded;
      case 'withdrawal':
        return Icons.account_balance_wallet_rounded;
      case 'admin_adjustment':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.monetization_on_rounded;
    }
  }

  Color _getCurrencyColor(String currencyType) {
    switch (currencyType) {
      case 'coins':
        return const Color(0xFFFFB800);
      case 'gems':
        return const Color(0xFF9C27B0);
      case 'cash':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  String _getCurrencySymbol(String currencyType) {
    return '₹'; // Cash only
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Transaction History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppColors.headerGradient),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Wallet Breakdown Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.accentGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cash Balance',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildWalletItem(
                              '₹ Cash',
                              '₹${(double.tryParse(_walletBreakdown['cash']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
                              Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Transaction List Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Text(
                        'Recent Transactions',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),

                  // Transaction List
                  _transactions.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 64,
                                    color: AppColors.textTertiary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No transactions yet',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final transaction = _transactions[index];
                                return _buildTransactionCard(transaction);
                              },
                              childCount: _transactions.length,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildWalletItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(dynamic transaction) {
    final type = transaction['transaction_type'] ?? '';
    final currencyType = transaction['currency_type'] ?? 'cash';
    final amount = double.tryParse(transaction['amount']?.toString() ?? '0') ?? 0;
    final isPositive = amount > 0;
    final description = transaction['description'] ?? transaction['offer_name'] ?? type;
    final date = _formatDate(transaction['created_at']);
    final offerImage = transaction['offer_image'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon or Offer Image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: offerImage != null ? Colors.transparent : _getCurrencyColor(currencyType).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              image: (offerImage != null && offerImage.toString().startsWith('http')) ? DecorationImage(
                image: NetworkImage(offerImage),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: (offerImage == null || !offerImage.toString().startsWith('http')) ? Icon(
              _getTransactionIcon(type),
              color: _getCurrencyColor(currencyType),
              size: 24,
            ) : null,
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isPositive ? '+' : ''}${_getCurrencySymbol(currencyType)}${amount.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isPositive ? AppColors.success : AppColors.error,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCurrencyColor(currencyType).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  currencyType.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getCurrencyColor(currencyType),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
