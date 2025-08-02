import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  // Initialize connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity status
    final connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectionStatus(connectivityResult);

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((result) => result != ConnectivityResult.none);
    
    if (wasOnline != _isOnline) {
      _connectivityController.add(_isOnline);
      print('Connection status changed: ${_isOnline ? 'Online' : 'Offline'}');
    }
  }

  void dispose() {
    _connectivitySubscription.cancel();
    _connectivityController.close();
  }
}

class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  final Map<String, dynamic> _cachedData = {};
  final Set<String> _pendingOperations = {};

  // Cache data for offline access
  void cacheData(String key, dynamic data) {
    _cachedData[key] = data;
  }

  // Get cached data
  T? getCachedData<T>(String key) {
    return _cachedData[key] as T?;
  }

  // Add operation to pending queue
  void addPendingOperation(String operation) {
    _pendingOperations.add(operation);
  }

  // Get pending operations
  Set<String> getPendingOperations() {
    return Set.from(_pendingOperations);
  }

  // Clear pending operation
  void clearPendingOperation(String operation) {
    _pendingOperations.remove(operation);
  }

  // Clear all cached data
  void clearCache() {
    _cachedData.clear();
  }

  // Get cache keys
  Set<String> getCacheKeys() {
    return _cachedData.keys.toSet();
  }
}

class OfflineWidget extends StatelessWidget {
  final Widget child;
  final Widget? offlineWidget;
  final VoidCallback? onRetry;

  const OfflineWidget({
    super.key,
    required this.child,
    this.offlineWidget,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: OfflineService().connectivityStream,
      initialData: OfflineService().isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;
        
        if (!isOnline) {
          return offlineWidget ?? _buildDefaultOfflineWidget(context);
        }
        
        return child;
      },
    );
  }

  Widget _buildDefaultOfflineWidget(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 120,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'You\'re Offline',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Some features may not be available without an internet connection.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B73FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: OfflineService().connectivityStream,
      initialData: OfflineService().isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? false;
        
        if (isOnline) {
          return const SizedBox.shrink();
        }
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.orange[700],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'You\'re offline - Some features may be limited',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
