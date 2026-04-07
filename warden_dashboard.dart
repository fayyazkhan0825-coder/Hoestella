import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/outpass_request.dart';
import '../../services/auth_service.dart';
import '../../services/outpass_service.dart';

class WardenDashboard extends StatelessWidget {
  const WardenDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Warden Dashboard'),
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
      body: StreamBuilder<List<OutpassRequest>>(
        stream: context.read<OutpassService>().streamPendingForWarden(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                  const SizedBox(height: 16),
                  Text('Error loading requests:\n${snapshot.error}', textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.orange.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  const Text('All caught up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  const Text('No pending requests to review.', style: TextStyle(color: Colors.black45)),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Pending Approvals (${requests.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return _OutpassRequestCard(request: request);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OutpassRequestCard extends StatelessWidget {
  final OutpassRequest request;

  const _OutpassRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM d, yyyy • h:mm a');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: Colors.orange.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  child: Text(request.studentName.isNotEmpty ? request.studentName[0].toUpperCase() : '?'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.studentName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Room: ${request.roomNumber} • Parent: ${request.parentPhone}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(Icons.event_note, 'Reason', request.reason),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.logout, 'Exit Time', dateFormatter.format(request.exitDateTime)),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.login, 'Return Time', dateFormatter.format(request.returnDateTime)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    onPressed: () => _showRejectDialog(context, request),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    onPressed: () => _approveRequest(context, request),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _approveRequest(BuildContext context, OutpassRequest request) async {
    try {
      await context.read<OutpassService>().updateStatus(
            id: request.id,
            status: OutpassStatus.approved,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request approved successfully'), backgroundColor: Colors.green),
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

  Future<void> _showRejectDialog(BuildContext context, OutpassRequest request) async {
    final remarksController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to reject the outpass request for ${request.studentName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: InputDecoration(
                labelText: 'Remarks (optional)',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange.shade300)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      try {
        await context.read<OutpassService>().updateStatus(
              id: request.id,
              status: OutpassStatus.rejected,
              remarks: remarksController.text.trim().isEmpty ? null : remarksController.text.trim(),
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request rejected'), backgroundColor: Colors.orange),
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
}
