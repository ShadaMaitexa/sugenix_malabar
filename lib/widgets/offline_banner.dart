import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sugenix/services/sync_service.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  Timer? _debounceTimer;
  bool _shouldShow = false;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sync = SyncService();
    return StreamBuilder<Map<String, bool>>(
      stream: sync.networkStatusStream(),
      builder: (context, snapshot) {
        // Only show if we have data
        if (!snapshot.hasData || snapshot.hasError) {
          _shouldShow = false;
          return const SizedBox.shrink();
        }
        
        final isFromCache = snapshot.data?['isFromCache'] ?? false;
        final hasPendingWrites = snapshot.data?['hasPendingWrites'] ?? false;
        final isOnline = snapshot.data?['isOnline'] ?? true;
        
        // Firebase often uses cache even when online (normal behavior during navigation)
        // Only show banner when we have pending writes that can't be synced
        // This prevents showing during normal navigation when Firebase just uses cache
        
        // Only show if we have pending writes AND we're offline (can't sync)
        // This is the only case where we truly need to show the banner
        final shouldShow = hasPendingWrites && isFromCache;
        
        // Debounce to prevent flickering during navigation
        if (shouldShow != _shouldShow) {
          _debounceTimer?.cancel();
          // Longer debounce to avoid showing during quick navigation
          _debounceTimer = Timer(const Duration(milliseconds: 2000), () {
            if (mounted) {
              setState(() {
                _shouldShow = shouldShow;
              });
            }
          });
        }
        
        // Always hide if we're online (not from cache) or no pending writes
        if (isOnline || !hasPendingWrites) {
          // Reset shouldShow if we come back online or pending writes are cleared
          if (_shouldShow) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  _shouldShow = false;
                });
              }
            });
          }
          return const SizedBox.shrink();
        }

        // Only render if we should show (after debounce)
        if (!_shouldShow) {
          return const SizedBox.shrink();
        }

        // Show banner only when we have pending writes and we're offline
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.orange,
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Offline • Syncing pending changes when online',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await sync.goOnline();
                },
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}


