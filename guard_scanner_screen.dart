import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../models/outpass_request.dart';
import '../../services/outpass_service.dart';

class GuardScannerScreen extends StatefulWidget {
  const GuardScannerScreen({super.key});

  @override
  State<GuardScannerScreen> createState() => _GuardScannerScreenState();
}

class _GuardScannerScreenState extends State<GuardScannerScreen> {
  bool _isHandling = false;
  String? _error;
  OutpassRequest? _request;
  final MobileScannerController _controller = MobileScannerController();

  Future<void> _handleCode(String rawValue) async {
    if (_isHandling) return;

    final outpassService = context.read<OutpassService>();

    setState(() {
      _isHandling = true;
      _error = null;
      _request = null;
    });

    try {
      await _controller.stop();
      final parsed = _parsePayload(rawValue);
      if (parsed == null) {
        setState(() {
          _error = 'Invalid QR payload';
        });
        return;
      }

      final requestId = parsed['requestId'] as String?;
      if (requestId == null || requestId.isEmpty) {
        setState(() {
          _error = 'QR is missing requestId';
        });
        return;
      }

      final request = await outpassService.getRequestById(requestId);

      if (!mounted) return;

      if (request == null) {
        setState(() {
          _error = 'Outpass not found (maybe deleted)';
        });
        return;
      }

      if (request.status != OutpassStatus.approved) {
        setState(() {
          _error =
              'Outpass is not approved. Current status: ${request.status.name}';
        });
        return;
      }

      setState(() {
        _request = request;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Scan failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isHandling = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _parsePayload(String rawValue) {
    if (!rawValue.startsWith('HOSTEL_OUTPASS:')) return null;
    final encoded = rawValue.substring('HOSTEL_OUTPASS:'.length);
    final bytes = base64Url.decode(encoded);
    final decoded = utf8.decode(bytes);
    final map = jsonDecode(decoded);
    if (map is! Map<String, dynamic>) return null;
    if (map['type'] != 'hostel_outpass') return null;
    return map;
  }

  Future<void> _markExit() async {
    final request = _request;
    if (request == null) return;
    await context.read<OutpassService>().markExit(request.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exit marked')),
    );
    setState(() {
      _request = request.copyWith(exitMarkedAt: DateTime.now());
    });
  }

  Future<void> _markEntry() async {
    final request = _request;
    if (request == null) return;
    await context.read<OutpassService>().markEntry(request.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry marked')),
    );
    setState(() {
      _request = request.copyWith(entryMarkedAt: DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Outpass QR'),
        actions: [
          IconButton(
            tooltip: 'Toggle torch',
            onPressed: () => _controller.toggleTorch(),
            icon: const Icon(Icons.flashlight_on_outlined),
          ),
          IconButton(
            tooltip: 'Switch camera',
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.cameraswitch_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                    final rawValue =
                        barcodes.isNotEmpty ? barcodes.first.rawValue : null;
                    if (rawValue != null) {
                      _handleCode(rawValue);
                    }
                  },
                ),
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Result', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (_error != null)
                        _ScannerBanner(
                          kind: _ScannerBannerKind.error,
                          text: _error!,
                        )
                      else if (request == null)
                        _ScannerBanner(
                          kind: _isHandling
                              ? _ScannerBannerKind.loading
                              : _ScannerBannerKind.info,
                          text: _isHandling
                              ? 'Processing…'
                              : 'Scan an approved outpass QR',
                        )
                      else ...[
                        Text(
                          request.studentName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Room: ${request.roomNumber}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Text('Reason: ${request.reason}'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: request.exitMarkedAt == null
                                    ? _markExit
                                    : null,
                                child: const Text('Mark Exit'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.tonal(
                                onPressed: (request.exitMarkedAt != null &&
                                        request.entryMarkedAt == null)
                                    ? _markEntry
                                    : null,
                                child: const Text('Mark Entry'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () async {
                            setState(() {
                              _error = null;
                              _request = null;
                            });
                            await _controller.start();
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan another'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ScannerBannerKind { info, loading, error }

class _ScannerBanner extends StatelessWidget {
  final _ScannerBannerKind kind;
  final String text;

  const _ScannerBanner({required this.kind, required this.text});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (kind) {
      case _ScannerBannerKind.loading:
        bg = Theme.of(context).colorScheme.primary.withValues(alpha: 0.10);
        fg = Theme.of(context).colorScheme.primary;
        icon = Icons.hourglass_top_rounded;
      case _ScannerBannerKind.error:
        bg = Theme.of(context).colorScheme.error.withValues(alpha: 0.10);
        fg = Theme.of(context).colorScheme.error;
        icon = Icons.error_outline;
      case _ScannerBannerKind.info:
        bg = const Color(0xFF111827).withValues(alpha: 0.06);
        fg = const Color(0xFF111827);
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

