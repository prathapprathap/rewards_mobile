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
        errorBuilder: (_, __, ___) => _buildFallback(settings),
      );
    }

    return Image.asset(
      'assets/images/coin.png',
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => _buildFallback(settings),
    );
  }

  Widget _buildFallback(SettingsProvider settings) {
    final symbol = settings.currencySymbol;
    // Use currency_rupee icon for ₹, else show text symbol
    if (symbol == '₹') {
      return Icon(
        Icons.currency_rupee,
        color: fallbackColor ?? AppColors.coinGold,
        size: size,
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            fontSize: size * 0.7,
            fontWeight: FontWeight.w800,
            color: fallbackColor ?? AppColors.coinGold,
          ),
        ),
      ),
    );
  }
}
