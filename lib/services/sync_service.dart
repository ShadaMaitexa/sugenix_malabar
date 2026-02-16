import 'package:cloud_firestore/cloud_firestore.dart';

class SyncService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Emits network/cache and pending-writes status by listening to a tiny collection
  Stream<Map<String, bool>> networkStatusStream() {
    return _db
        .collection('_sync_probe')
        .limit(1)
        .snapshots(includeMetadataChanges: true)
        .map((snap) {
      // isFromCache = true means we're offline or using cached data
      // If isFromCache is false, we're online
      final isFromCache = snap.metadata.isFromCache;
      final hasPendingWrites = snap.metadata.hasPendingWrites;
      
      return {
        'isFromCache': isFromCache,
        'hasPendingWrites': hasPendingWrites,
        'isOnline': !isFromCache, // If not from cache, we're online
      };
    });
  }

  Future<void> goOffline() => _db.disableNetwork();
  Future<void> goOnline() => _db.enableNetwork();
}


