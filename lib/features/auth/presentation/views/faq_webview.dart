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
    print('=== RETRYING FAQ LOAD ===');
    print('Timestamp: ${DateTime.now()}');
    print('Current loading state: $_isLoading');
    print('Controller: $_controller');
    print('=========================');
    
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _webViewFailed = false;
    });
    _startTimeout();

    // Try the actual FAQ URL
    _controller?.loadRequest(Uri.parse('https://evolv28.com/faq')).catchError((error) {
      print('=== RETRY LOAD REQUEST ERROR ===');
      print('Error: $error');
      print('Error Type: ${error.runtimeType}');
      print('Timestamp: ${DateTime.now()}');
      print('================================');
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Retry failed: $error';
      });
    });
  }

  void _retryWithDetailedLogging() {
    print('=== RETRYING FAQ LOAD WITH DETAILED LOGGING ===');
    print('Timestamp: ${DateTime.now()}');
    print('Current loading state: $_isLoading');
    print('Controller: $_controller');
    print('WebView Failed: $_webViewFailed');
    print('Error Message: $_errorMessage');
    print('===============================================');
    
    setState(() {
      _errorMessage = null;
      _isLoading = true;
      _webViewFailed = false;
    });
    _startTimeout();

    // Retry with detailed logging
    _controller?.loadRequest(Uri.parse('https://evolv28.com/faq')).catchError((error) {
      print('=== DETAILED RETRY LOAD REQUEST ERROR ===');
      print('Error: $error');
      print('Error Type: ${error.runtimeType}');
      print('Stack Trace: ${StackTrace.current}');
      print('Timestamp: ${DateTime.now()}');
      print('=========================================');
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Detailed retry failed: $error';
      });
    });
  }
  
  void _openInExternalBrowser() async {
    final Uri url = Uri.parse('https://evolv28.com/faq');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }

  void _printDebugInfo() {
    print('=== WEBVIEW DEBUG INFO ===');
    print('Loading state: $_isLoading');
    print('Error message: $_errorMessage');
    print('Timeout timer active: ${_timeoutTimer?.isActive}');
    print('==========================');
  }

  void _initializeWebView() {
    print('=== INITIALIZING WEBVIEW ===');
    print('Timestamp: ${DateTime.now()}');
    print('============================');
    
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
        )
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('=== PAGE LOADING STARTED ===');
              print('URL: $url');
              print('Timestamp: ${DateTime.now()}');
              print('============================');
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            },
            onPageFinished: (String url) {
              print('=== PAGE LOADING FINISHED ===');
              print('URL: $url');
              print('Timestamp: ${DateTime.now()}');
              print('=============================');
              _timeoutTimer?.cancel();
              setState(() {
                _isLoading = false;
                _errorMessage = null;
              });
            },
            onWebResourceError: (WebResourceError error) {
              _timeoutTimer?.cancel();
              print('=== WEBVIEW RESOURCE ERROR ===');
              print('Error Type: ${error.errorType}');
              print('Error Code: ${error.errorCode}');
              print('Description: ${error.description}');
              print('Is For Main Frame: ${error.isForMainFrame}');
              print('Timestamp: ${DateTime.now()}');
              print('==============================');
              
              String errorMessage = 'Failed to load FAQ.\n\n';
              errorMessage += 'Error Code: ${error.errorCode}\n';
              errorMessage += 'Description: ${error.description}\n\n';
              
              if (error.errorCode == -2) {
                errorMessage += 'This appears to be a network connectivity issue.';
              } else if (error.errorCode == -6) {
                errorMessage += 'This appears to be a certificate or SSL issue.';
              } else if (error.errorCode == -8) {
                errorMessage += 'This appears to be a timeout issue.';
              } else {
                errorMessage += 'Please check your internet connection and try again.';
              }
              
              setState(() {
                _isLoading = false;
                _errorMessage = errorMessage;
              });
            },
            onNavigationRequest: (NavigationRequest request) {
              print('=== NAVIGATION REQUEST ===');
              print('URL: ${request.url}');
              print('Timestamp: ${DateTime.now()}');
              print('==========================');
              return NavigationDecision.navigate;
            },
          ),
        );
      
      print('=== WEBVIEW CONTROLLER CREATED ===');
      print('Controller: $_controller');
      print('==================================');
      
      // Load the URL
      _controller?.loadRequest(Uri.parse('https://evolv28.com/faq')).catchError((error) {
        print('=== LOAD REQUEST ERROR ===');
        print('Error: $error');
        print('Error Type: ${error.runtimeType}');
        print('Timestamp: ${DateTime.now()}');
        print('==========================');
        
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load FAQ: $error';
        });
      });
      
    } catch (e, stackTrace) {
      print('=== WEBVIEW INITIALIZATION ERROR ===');
      print('Error: $e');
      print('Error Type: ${e.runtimeType}');
      print('Stack Trace: $stackTrace');
      print('Timestamp: ${DateTime.now()}');
      print('====================================');
      
      setState(() {
        _webViewFailed = true;
        _isLoading = false;
        _errorMessage = 'WebView initialization failed: $e';
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
                        if (!_webViewFailed && _errorMessage == null && _controller != null)
                          WebViewWidget(controller: _controller!),
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
