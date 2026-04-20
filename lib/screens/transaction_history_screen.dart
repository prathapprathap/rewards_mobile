import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: AppColors.primary),
        title: Text(
          widget.isEarnings ? 'EARNINGS HISTORY' : 'REDEEM HISTORY',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTransactions,
        color: AppColors.primary,
        child: _isLoading && _transactions.isEmpty
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : filteredList.isEmpty
                ? Center(child: Text('No data found', style: GoogleFonts.inter(color: Colors.grey)))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredList.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == filteredList.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: CircularProgressIndicator()),
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
    final String description = tx['description'] ?? 'Activity reward';
    final double amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0;
    final String status = tx['status']?.toString().toLowerCase() ?? 'success';
    final String date = tx['created_at'] != null 
        ? tx['created_at'].toString().substring(0, 16).replaceAll('T', ' ') 
        : 'Recently';

    IconData icon;
    Color iconColor = AppColors.primary;

    switch (type.toLowerCase()) {
      case 'spin':
        icon = Icons.refresh;
        break;
      case 'referral':
        icon = Icons.share;
        break;
      case 'promo':
      case 'signup_bonus':
        icon = Icons.stars;
        break;
      case 'withdrawal':
        icon = Icons.account_balance_wallet;
        break;
      case 'refund':
        icon = Icons.undo;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.card_giftcard;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
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
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      date,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
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
            '${amount >= 0 ? '+' : ''}${amount.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: amount >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'pending': color = Colors.orange; break;
      case 'success': color = Colors.green; break;
      case 'rejected': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}
