import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/settings_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_toast.dart';

/// Standalone "Fill Form" screen shown when an offer requires screenshot
/// verification. Users enter contact info + upload N screenshots, then submit.
///
/// Pops `true` after a successful upload so the caller can refresh.
class FillFormScreen extends StatefulWidget {
  final int offerId;
  final String offerName;
  final double rewardAmount;
  final int requiredCount;
  final List<String> demoScreenshots;

  const FillFormScreen({
    super.key,
    required this.offerId,
    required this.offerName,
    required this.rewardAmount,
    required this.requiredCount,
    required this.demoScreenshots,
  });

  @override
  State<FillFormScreen> createState() => _FillFormScreenState();
}

class _FillFormScreenState extends State<FillFormScreen> {
  final TextEditingController _contactController = TextEditingController();
  final List<XFile> _pickedImages = [];
  bool _isSubmitting = false;
  String? _contactError;

  int get _requiredCount => widget.requiredCount.clamp(1, 5);

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  String? _validateContact(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Enter your WhatsApp number or email';
    final phoneRe = RegExp(r'^\+?\d[\d\s-]{7,18}$');
    final emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (phoneRe.hasMatch(v) || emailRe.hasMatch(v)) return null;
    return 'Enter a valid WhatsApp number or email';
  }

  Future<void> _pickImages() async {
    if (_pickedImages.length >= _requiredCount) return;
    final picker = ImagePicker();
    final remaining = _requiredCount - _pickedImages.length;

    if (remaining > 1) {
      final picked = await picker.pickMultiImage(imageQuality: 75, maxWidth: 1600);
      if (picked.isEmpty) return;
      setState(() {
        _pickedImages.addAll(picked.take(remaining));
      });
    } else {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1600,
      );
      if (picked == null) return;
      setState(() {
        _pickedImages.add(picked);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final userId = Provider.of<UserProvider>(context, listen: false).user?.id;
    if (userId == null) {
      _toast('Please login first', isError: true);
      return;
    }

    final err = _validateContact(_contactController.text);
    if (err != null) {
      setState(() => _contactError = err);
      _toast(err, isError: true);
      return;
    }
    setState(() => _contactError = null);

    if (_pickedImages.length < _requiredCount) {
      _toast(
        'Please upload $_requiredCount screenshot${_requiredCount > 1 ? 's' : ''}',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dataUrls = <String>[];
      for (final xf in _pickedImages) {
        final bytes = await File(xf.path).readAsBytes();
        final ext = xf.path.split('.').last.toLowerCase();
        final mime = (ext == 'jpg' || ext == 'jpeg')
            ? 'image/jpeg'
            : (ext == 'webp')
                ? 'image/webp'
                : 'image/png';
        dataUrls.add('data:$mime;base64,${base64Encode(bytes)}');
      }

      await ApiService().uploadTaskSubmission(
        userId: userId,
        offerId: widget.offerId,
        imageBase64DataUrls: dataUrls,
        contactInfo: _contactController.text.trim(),
      );

      if (!mounted) return;
      _toast('Screenshot uploaded. Pending admin review.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        _toast(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _toast(String message, {bool isError = false}) {
    CustomToast.show(
      context,
      message,
      title: isError ? 'Oops!' : 'Success',
      isError: isError,
    );
  }

  void _previewImage(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.black26,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image,
                        color: Colors.white70, size: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(settings),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Whatsapp Number or Email'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _contactController,
                      enabled: !_isSubmitting,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        if (_contactError != null) {
                          setState(() => _contactError = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g. 9876543210 or you@email.com',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.outline,
                        ),
                        errorText: _contactError,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _sectionLabel('Upload Document'),
                    const SizedBox(height: 10),
                    _buildUploadArea(),
                    const SizedBox(height: 24),
                    _buildSubmitButton(),
                    if (widget.demoScreenshots.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      Center(
                        child: Text(
                          'Tap to preview demo images',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildDemoGallery(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: AppColors.onSurface,
        ),
      );

  Widget _buildTopBar(SettingsProvider settings) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.primaryFixed.withValues(alpha: 0.20),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fill Form',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    settings.currencySymbol,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.rewardAmount.toStringAsFixed(2),
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    final canAdd = _pickedImages.length < _requiredCount && !_isSubmitting;
    return GestureDetector(
      onTap: canAdd ? _pickImages : null,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1.4,
            style: BorderStyle.solid,
          ),
        ),
        child: _pickedImages.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.upload_file,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Upload (${_pickedImages.length}/$_requiredCount)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (int i = 0; i < _pickedImages.length; i++)
                        _buildPickedThumb(i),
                      if (canAdd) _buildAddTile(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Upload (${_pickedImages.length}/$_requiredCount)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPickedThumb(int i) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(_pickedImages[i].path),
            width: 92,
            height: 92,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: _isSubmitting ? null : () => _removeImage(i),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddTile() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.center,
        child: Icon(Icons.add, color: AppColors.primary, size: 28),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final enabled = !_isSubmitting && _pickedImages.length >= _requiredCount;
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: enabled ? _submit : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? [AppColors.primary, AppColors.primaryContainer]
                  : [
                      AppColors.outlineVariant,
                      AppColors.outlineVariant,
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(99),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Submit',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoGallery() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final url in widget.demoScreenshots)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => _previewImage(url),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        url,
                        width: 140,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 140,
                          height: 220,
                          color: AppColors.surfaceContainer,
                          alignment: Alignment.center,
                          child: Icon(Icons.broken_image,
                              color: AppColors.outline, size: 28),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Demo\nScreenshot',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
}
