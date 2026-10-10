
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreQueryBuilder {
  FirestoreQueryBuilder(this._collection);

  final CollectionReference<Map<String, dynamic>> _collection;

  Query<Map<String, dynamic>> _query() => _collection;

  Query<Map<String, dynamic>> whereEqualTo(
    String field,
    Object? value,
  ) {
    return _query().where(field, isEqualTo: value);
  }

  Query<Map<String, dynamic>> whereIn(
    String field,
    List<Object?> values,
  ) {
    if (values.isEmpty) {
      throw ArgumentError('whereIn values cannot be empty.');
    }
    return _query().where(field, whereIn: values);
  }

  Query<Map<String, dynamic>> orderBy(
    String field, {
    bool descending = false,
  }) {
    return _query().orderBy(field, descending: descending);
  }

  Query<Map<String, dynamic>> limitTo(int count) {
    if (count < 1) {
      throw ArgumentError.value(count, 'count', 'Must be at least 1.');
    }
    return _query().limit(count);
  }

  Query<Map<String, dynamic>> build({
    List<FirestoreFilter> filters = const [],
    String? orderByField,
    bool descending = false,
    int? limit,
  }) {
    Query<Map<String, dynamic>> query = _collection;

    for (final filter in filters) {
      query = query.where(
        filter.field,
        isEqualTo: filter.value,
      );
    }

    if (orderByField != null) {
      query = query.orderBy(
        orderByField,
        descending: descending,
      );
    }

    if (limit != null) {
      if (limit < 1) {
        throw ArgumentError.value(limit, 'limit', 'Must be at least 1.');
      }
      query = query.limit(limit);
    }

    return query;
  }
}

class FirestoreFilter {
  const FirestoreFilter({
    required this.field,
    required this.value,
  });

  final String field;
  final Object? value;
}
