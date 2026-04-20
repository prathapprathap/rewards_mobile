import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../constants/colors.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  final String offerName;

  const WebViewScreen({super.key, required this.url, required this.offerName});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isInitialized = false;
  bool _isRedirected = false;
  bool _isPageLoading = true;
  String? _errorMessage;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();

_controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setNavigationDelegate(
    NavigationDelegate(
      onNavigationRequest: (request) {
        final url = request.url;
        debugPrint('🌐 WebView Navigating to: $url');

        if (_shouldOpenExternally(url)) {
          _launchStore(url);
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },

      onPageStarted: (url) {
        if (!mounted) return;
        setState(() {
          _currentUrl = url;
          _isPageLoading = true;
          _errorMessage = null;
        });

        if (_shouldOpenExternally(url)) {
          _launchStore(url);
        }
      },

      onPageFinished: (url) {
        if (!mounted) return;
        setState(() {
          _currentUrl = url;
          _isPageLoading = false;
        });
      },

      onUrlChange: (change) {
        final url = change.url;
        if (!mounted || url == null) return;

        setState(() => _currentUrl = url);

        if (_shouldOpenExternally(url)) {
          _launchStore(url);
        }
      },

      onWebResourceError: (error) {
        debugPrint('❌ WebView Error: ${error.description}');

        final desc = error.description.toLowerCase();

        if (desc.contains('err_cleartext_not_permitted') ||
            desc.contains('err_blocked_by_orb') ||
            desc.contains('err_unknown_url_scheme')) {
          _openOfferExternally(_currentUrl ?? widget.url);
          return;
        }

        if (!mounted) return;
        setState(() {
          _isPageLoading = false;
          _errorMessage = error.description;
        });
      },
    ),
  );

_startDeepLinkFlow();
  }

  Future<void> _startDeepLinkFlow() async {
    // Clear cookies and cache for "no history" requirement
    try {
      final cookieManager = WebViewCookieManager();
      await cookieManager.clearCookies();
      await _controller.clearCache();
    } catch (e) {
      debugPrint('Error clearing cookies/cache: $e');
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
        _isPageLoading = true;
        _errorMessage = null;
        _currentUrl = widget.url;
      });
      _controller.loadRequest(Uri.parse(widget.url));

      // Auto-timeout after 15 seconds if no redirection happens
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && !_isRedirected) {
          _handleTimeout();
        }
      });
    }
  }

  void _handleTimeout() {
    if (_isRedirected || !_isPageLoading) return;
    _openOfferExternally(widget.url);
  }

  bool _shouldOpenExternally(String url) {
    return url.startsWith('market://') ||
        url.startsWith('intent://') ||
        url.contains('play.google.com/store/apps/details');
  }

  bool _shouldOpenInBrowserAfterError(String? description) {
    final message = (description ?? '').toLowerCase();
    return message.contains('err_blocked_by_orb') ||
        message.contains('err_unknown_url_scheme');
  }

 Future<void> _openOfferExternally(String url) async {
  if (_isRedirected) return;
  if (mounted) {
    setState(() {
      _isRedirected = true;
      _isPageLoading = false;
    });
  }

  // Upgrade HTTP to HTTPS before opening
  final safeUrl = url.startsWith('http://')
      ? url.replaceFirst('http://', 'https://')
      : url;

  try {
    final launched = await launchUrl(
      Uri.parse(safeUrl),
      mode: LaunchMode.inAppBrowserView,
    );
    if (!mounted) return;
    if (launched) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _isRedirected = false;
      _errorMessage = 'Could not open this offer in your browser.';
    });
  } catch (_) {
    if (!mounted) return;
    setState(() {
      _isRedirected = false;
      _errorMessage = 'Could not open this offer in your browser.';
    });
  }
}

  Future<void> _launchStore(String url) async {
    if (_isRedirected) return;
    setState(() => _isRedirected = true);

    final uri = Uri.parse(
      url.startsWith('market://')
          ? url
          : url.contains('details?id=')
          ? 'market://details?id=${url.split('details?id=')[1]}'
          : url,
    );

    try {
      // Use externalNonBrowserApplication to ensure it targets the Play Store app specifically
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
      if (!launched) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Fallback
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
          return;
        }
        if (context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            widget.offerName,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                await _controller.goBack();
                return;
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ),
        body: Stack(
          children: [
            if (_isInitialized)
              Positioned.fill(child: WebViewWidget(controller: _controller)),
            if (_errorMessage != null)
              Positioned.fill(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 56,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Could not load this offer page',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () => _controller.loadRequest(
                                Uri.parse(widget.url),
                              ),
                              child: const Text('Retry'),
                            ),
                            OutlinedButton(
                              onPressed: () => _openOfferExternally(
                                _currentUrl ?? widget.url,
                              ),
                              child: const Text('Open in Browser'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (_isPageLoading && !_isRedirected)
              Container(
                color: Colors.white.withValues(alpha: 0.94),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 24),
                      Text(
                        'Opening offer...',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentUrl == null
                            ? 'Please wait'
                            : 'Loading partner page',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
