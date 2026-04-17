import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String offerName;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.offerName,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isRedirected = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            if (url.contains('play.google.com/store/apps/details') || url.startsWith('market://')) {
              _launchStore(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
             if (url.contains('play.google.com/store/apps/details') || url.startsWith('market://')) {
              _launchStore(url);
            }
          },
          onUrlChange: (change) {
            final url = change.url;
            if (url != null && (url.contains('play.google.com/store/apps/details') || url.startsWith('market://'))) {
               _launchStore(url);
            }
          }
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _launchStore(String url) async {
    if (_isRedirected) return;
    setState(() => _isRedirected = true);
    
    final uri = Uri.parse(url.startsWith('market://') ? url : url.replaceFirst('https://play.google.com/store/apps/details', 'market://details'));
    
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Fallback to https if market fails
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.offerName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.primary)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
      ),
      body: Stack(
        children: [
          // The WebView itself (can be invisible or show loading)
          WebViewWidget(controller: _controller),
          if (!_isRedirected)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      'Redirecting to Play Store...',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please do not close the app',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant.withOpacity(0.5),
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
