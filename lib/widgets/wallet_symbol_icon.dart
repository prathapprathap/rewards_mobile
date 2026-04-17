import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../providers/settings_provider.dart';

class WalletSymbolIcon extends StatelessWidget {
  final double size;
  final Color? fallbackColor;
  final BoxFit fit;

  const WalletSymbolIcon({
    super.key,
    required this.size,
    this.fallbackColor,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: true);
    final imageUrl = settings.getString('wallet_symbol_image_url', '').trim();

    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    return Image.asset(
      'assets/images/coin.png',
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Icon(
      Icons.monetization_on,
      color: fallbackColor ?? AppColors.coinGold,
      size: size,
    );
  }
}
