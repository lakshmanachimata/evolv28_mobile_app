import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/routing/app_router_config.dart';

class FAQWebView extends StatefulWidget {
  const FAQWebView({super.key});

  @override
  State<FAQWebView> createState() => _FAQWebViewState();
}

class _FAQWebViewState extends State<FAQWebView> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _timeoutTimer;
  bool _webViewFailed = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _startTimeout();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  void _startTimeout() {
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && _isLoading) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Page is taking too long to load. Please check your internet connection and try again.';
        });
      }
    });
  }

  void _retryWithFallback() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _webViewFailed = false;
    });
    _startTimeout();
    _controller?.loadRequest(Uri.parse('https://evolv28.com/faq'));
  }

  void _retryWithDetailedLogging() {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _webViewFailed = false;
    });
    _startTimeout();
    _controller?.loadRequest(Uri.parse('https://evolv28.com/faq'));
  }
  
  void _openInExternalBrowser() async {
    final Uri url = Uri.parse('https://evolv28.com/faq');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }


  void _initializeWebView() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            },
            onPageFinished: (String url) {
              _timeoutTimer?.cancel();
              setState(() {
                _isLoading = false;
                _errorMessage = null;
              });
            },
            onWebResourceError: (WebResourceError error) {
              _timeoutTimer?.cancel();
              setState(() {
                _isLoading = false;
                _errorMessage = 'Failed to load FAQ. Please check your internet connection.';
              });
            },
            onNavigationRequest: (NavigationRequest request) {
              return NavigationDecision.navigate;
            },
          ),
        );
      
      // Load the URL
      _controller?.loadRequest(Uri.parse('https://evolv28.com/faq'));
      
    } catch (e) {
      setState(() {
        _webViewFailed = true;
        _isLoading = false;
        _errorMessage = 'WebView initialization failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          _buildBackground(),

          // Main content
          _buildMainContent(context),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Image.asset(
        'assets/images/term-background.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Stack(
      children: [
        // evolv28 logo at top center
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(child: _buildTopLogo(context)),
        ),

        // Bottom sheet content
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.86,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  // Header bar
                  _buildHeader(context),

                  // WebView content
                  Expanded(
                    child: Stack(
                      children: [
                        // Always show WebView if controller exists, regardless of loading state
                        if (_controller != null)
                          WebViewWidget(controller: _controller!),
                        
                        // Show message when controller is null
                        if (_controller == null)
                          const Center(
                            child: Text(
                              'Initializing WebView...',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        
                        
                        // Show error overlay if WebView failed
                        if (_webViewFailed)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'WebView Initialization Failed',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _errorMessage ?? 'Unknown error occurred',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _openInExternalBrowser,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF17961),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Open in Browser'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!_webViewFailed && _errorMessage != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _errorMessage = null;
                                                _isLoading = true;
                                              });
                                              _startTimeout();
                                              _controller?.reload();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFF17961,
                                              ),
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Retry'),
                                          ),
                                          const SizedBox(width: 16),
                                          ElevatedButton(
                                            onPressed: _retryWithDetailedLogging,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Retry with Logging'),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: () async {
                                          final Uri url = Uri.parse('https://evolv28.com/faq');
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url, mode: LaunchMode.externalApplication);
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.orange,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Open in Browser'),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Check console for detailed error information',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_isLoading && _errorMessage == null && !_webViewFailed)
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFF17961),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Loading FAQ...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'This may take a few moments',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _isLoading = false;
                                          _errorMessage =
                                              'Loading cancelled by user.';
                                        });
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 16),
                                    TextButton(
                                      onPressed: () async {
                                        final Uri url = Uri.parse('https://evolv28.com/faq');
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url, mode: LaunchMode.externalApplication);
                                        }
                                      },
                                      child: const Text('Open in Browser'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopLogo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40), // Spacer to center the logo
          // evolv28 logo image
          Image.asset(
            'assets/images/evolv_text.png',
            width: MediaQuery.of(context).size.width * 0.25,
            fit: BoxFit.contain,
          ),
          // Settings icon
          GestureDetector(
            onTap: () {
              context.go(AppRoutes.settings);
            },
            child: const Icon(Icons.settings, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Row(
        children: [
          // Close button
          GestureDetector(
            onTap: () => context.go(AppRoutes.settings),
            child: const Icon(Icons.close, color: Colors.black, size: 24),
          ),

          // FAQ title
          const Expanded(
            child: Center(
              child: Text(
                'FAQ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),

          // Empty space to balance the close button
          const SizedBox(width: 24),
        ],
      ),
    );
  }
}
