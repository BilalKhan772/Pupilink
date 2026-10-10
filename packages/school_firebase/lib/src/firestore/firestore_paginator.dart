
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestorePaginator {
  FirestorePaginator({
    required this.query,
    this.pageSize = 20,
  }) {
    if (pageSize < 1) {
      throw ArgumentError.value(
        pageSize,
        'pageSize',
        'Must be at least 1.',
      );
    }
  }

  final Query<Map<String, dynamic>> query;
  final int pageSize;

  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;

  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> nextPage()
      async {
    if (_isLoading || !_hasMore) return [];

    _isLoading = true;

    try {
      Query<Map<String, dynamic>> pageQuery = query.limit(pageSize);

      if (_lastDocument != null) {
        pageQuery = pageQuery.startAfterDocument(_lastDocument!);
      }

      final snapshot = await pageQuery.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      _hasMore = snapshot.docs.length == pageSize;

      return snapshot.docs;
    } finally {
      _isLoading = false;
    }
  }

  void reset() {
    _lastDocument = null;
    _hasMore = true;
    _isLoading = false;
  }
}
