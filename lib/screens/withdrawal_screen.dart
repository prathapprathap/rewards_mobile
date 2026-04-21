import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_toast.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();
  String _selectedMethod = 'UPI';
  bool _isSubmitting = false;

  final List<String> _methods = ['UPI', 'Paytm', 'Bank Transfer'];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user?.upiId != null) {
      _detailsController.text = user!.upiId!;
    }
  }

  Future<void> _submitRequest() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    if (userId == null) return;

    final amountStr = _amountController.text.trim();
    final details = _detailsController.text.trim();

    if (amountStr.isEmpty || details.isEmpty) {
      CustomToast.show(context, 'Please fill all fields', title: 'Error', isError: true);
      return;
    }

    final double amount = double.tryParse(amountStr) ?? 0;
    if (amount <= 0) {
      CustomToast.show(context, 'Invalid amount', title: 'Error', isError: true);
      return;
    }

    if (amount > (userProvider.user?.walletBalance ?? 0)) {
      CustomToast.show(context, 'Insufficient balance', title: 'Error', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final api = ApiService();
      await api.requestWithdrawal(
        userId: userId,
        amount: amount,
        method: _selectedMethod,
        details: details,
      );

      // Save payout details for future use
      await api.updatePayoutDetails(userId, details);

      if (mounted) {
        CustomToast.show(
          context,
          'Withdrawal request submitted!',
          title: 'Success!',
        );
        userProvider.refreshUser();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          title: 'Error',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'WITHDRAW',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w900,
            color: AppColors.primary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 32),
            Text(
              'WITHDRAWAL DETAILS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurfaceVariant.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildMethodSelector(),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _amountController,
              label: 'Amount (₹)',
              hint: 'Enter amount to withdraw',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              controller: _detailsController,
              label: 'Payout Details',
              hint: _selectedMethod == 'UPI' 
                  ? 'Enter UPI ID (e.g. name@upi)' 
                  : _selectedMethod == 'Paytm'
                      ? 'Enter Paytm Mobile Number'
                      : 'Enter Account No & IFSC',
              maxLines: 3,
            ),
            const SizedBox(height: 48),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final user = Provider.of<UserProvider>(context).user;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'AVAILABLE BALANCE',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${settings.currencySymbol}${(user?.walletBalance ?? 0).toStringAsFixed(2)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMethod,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
          items: _methods.map((String method) {
            return DropdownMenuItem<String>(
              value: method,
              child: Text(
                method,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _selectedMethod = value);
          },
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurfaceVariant.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant.withOpacity(0.3),
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(20),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                'SUBMIT REQUEST',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}
