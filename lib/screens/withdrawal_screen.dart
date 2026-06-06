import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_toast.dart';
import '../providers/settings_provider.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _amountController = TextEditingController();
  final _detailsController = TextEditingController();
  // Structured bank fields (used only when method is "Bank Transfer")
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _mobileController = TextEditingController();
  String _selectedMethod = 'UPI';
  bool _isSubmitting = false;
  // Mobile is collected only the first time; reused for later withdrawals.
  bool _needsMobile = true;

  final List<String> _methods = ['UPI', 'Paytm', 'Bank Transfer'];

  bool get _isBank => _selectedMethod == 'Bank Transfer';

  @override
  void initState() {
    super.initState();
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user?.upiId != null) {
      _detailsController.text = user!.upiId!;
    }
    final savedMobile = user?.mobile?.trim() ?? '';
    _needsMobile = savedMobile.isEmpty;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  /// Builds the `details` string sent to the backend. For bank transfers we
  /// store a structured, parseable string so the admin panel can show the
  /// account number and IFSC separately.
  String _buildDetails() {
    if (_isBank) {
      final name = _accountNameController.text.trim();
      final acc = _accountNumberController.text.trim();
      final ifsc = _ifscController.text.trim().toUpperCase();
      final bank = _bankNameController.text.trim();
      final parts = [
        'Name: $name',
        'A/C: $acc',
        'IFSC: $ifsc',
        if (bank.isNotEmpty) 'Bank: $bank',
      ];
      return parts.join(' | ');
    }
    return _detailsController.text.trim();
  }

  /// Returns an error message if the current input is invalid, else null.
  String? _validateDetails() {
    if (_isBank) {
      if (_accountNameController.text.trim().isEmpty) {
        return 'Please enter the account holder name';
      }
      final acc = _accountNumberController.text.trim();
      if (acc.isEmpty) return 'Please enter the account number';
      if (acc.length < 6 || !RegExp(r'^\d+$').hasMatch(acc)) {
        return 'Enter a valid account number';
      }
      final ifsc = _ifscController.text.trim().toUpperCase();
      if (ifsc.isEmpty) return 'Please enter the IFSC code';
      if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
        return 'Enter a valid IFSC code (e.g. SBIN0001234)';
      }
      return null;
    }
    if (_detailsController.text.trim().isEmpty) {
      return 'Please enter your payout details';
    }
    return null;
  }

  Future<void> _submitRequest() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user?.id;
    if (userId == null) return;

    final amountStr = _amountController.text.trim();

    if (amountStr.isEmpty) {
      CustomToast.show(context, 'Please enter an amount', title: 'Error', isError: true);
      return;
    }

    final detailsError = _validateDetails();
    if (detailsError != null) {
      CustomToast.show(context, detailsError, title: 'Error', isError: true);
      return;
    }

    final mobile = _mobileController.text.trim();
    if (_needsMobile) {
      if (!RegExp(r'^\d{10}$').hasMatch(mobile)) {
        CustomToast.show(context, 'Enter a valid 10-digit mobile number',
            title: 'Error', isError: true);
        return;
      }
    }

    final details = _buildDetails();

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
        mobile: _needsMobile ? mobile : null,
      );

      // Save UPI id for future prefill (skip for bank/Paytm details).
      if (_selectedMethod == 'UPI') {
        await api.updatePayoutDetails(userId, details);
      }

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
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
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
            if (_isBank) ...[
              _buildTextField(
                controller: _accountNameController,
                label: 'Account Holder Name',
                hint: 'Enter name as per bank',
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _accountNumberController,
                label: 'Account Number',
                hint: 'Enter bank account number',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _ifscController,
                label: 'IFSC Code',
                hint: 'e.g. SBIN0001234',
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 24),
              _buildTextField(
                controller: _bankNameController,
                label: 'Bank Name (optional)',
                hint: 'e.g. State Bank of India',
              ),
            ] else
              _buildTextField(
                controller: _detailsController,
                label: 'Payout Details',
                hint: _selectedMethod == 'UPI'
                    ? 'Enter UPI ID (e.g. name@upi)'
                    : 'Enter Paytm Mobile Number',
              ),
            if (_needsMobile) ...[
              const SizedBox(height: 24),
              _buildTextField(
                controller: _mobileController,
                label: 'Mobile Number',
                hint: 'Enter 10-digit mobile number',
                keyboardType: TextInputType.phone,
              ),
            ],
            const SizedBox(height: 48),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final user = Provider.of<UserProvider>(context).user;
    final settings = Provider.of<SettingsProvider>(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
    TextCapitalization textCapitalization = TextCapitalization.none,
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
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
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
