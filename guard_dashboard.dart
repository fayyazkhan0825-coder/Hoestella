import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/outpass_request.dart';
import '../../services/auth_service.dart';
import '../../services/outpass_service.dart';
import '../guard/guard_scanner_screen.dart';

class GuardDashboard extends StatelessWidget {
  const GuardDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().signOut();
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildScannerSection(context),
          Expanded(
            child: StreamBuilder<List<OutpassRequest>>(
              stream: context.read<OutpassService>().streamApprovedForGuard(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 60, color: Colors.orange.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text('No active outpasses to manage', style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        'Approved Outpasses (${requests.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: requests.length,
                        padding: const EdgeInsets.only(bottom: 24),
                        itemBuilder: (context, index) {
                          return _GuardActionCard(request: requests[index]);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.qr_code_scanner, size: 48, color: Colors.orange.shade700),
          const SizedBox(height: 12),
          const Text(
            'Scan Outpass QR',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap here to open the scanner',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Open Scanner'),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GuardScannerScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GuardActionCard extends StatelessWidget {
  final OutpassRequest request;

  const _GuardActionCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM d, h:mm a');
    final isExited = request.exitMarkedAt != null;
    final isEntered = request.entryMarkedAt != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isExited ? Colors.blue.shade100 : Colors.green.shade100,
              foregroundColor: isExited ? Colors.blue.shade800 : Colors.green.shade800,
              radius: 24,
              child: Icon(isExited ? Icons.directions_walk : Icons.domain),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Room: ${request.roomNumber}',
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  if (request.exitMarkedAt != null)
                    Text('Exited: ${dateFormatter.format(request.exitMarkedAt!)}', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                  if (request.entryMarkedAt != null)
                    Text('Entered: ${dateFormatter.format(request.entryMarkedAt!)}', style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
                ],
              ),
            ),
            Column(
              children: [
                if (!isExited)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _markExit(context, request),
                    child: const Text('Mark Exit'),
                  )
                else if (!isEntered)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _markEntry(context, request),
                    child: const Text('Mark Entry'),
                  )
                else
                  const Chip(
                    label: Text('Completed'),
                    backgroundColor: Colors.black12,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markExit(BuildContext context, OutpassRequest request) async {
    try {
      await context.read<OutpassService>().markExit(request.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exit marked for ${request.studentName}'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markEntry(BuildContext context, OutpassRequest request) async {
    try {
      await context.read<OutpassService>().markEntry(request.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Entry marked for ${request.studentName}'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}