import 'dart:async';
import 'package:flutter/foundation.dart';

class MockDatabase {
  static final MockDatabase instance = MockDatabase._();
  MockDatabase._() {
    _initData();
  }

  final MockAuth auth = MockAuth();

  MockDatabase get client => this;
  
  // In-memory tables
  final Map<String, List<Map<String, dynamic>>> _tables = {
    'profiles': [],
    'bookings': [],
    'vehicles': [],
    'addresses': [],
    'feedback': [],
    'notifications': [],
  };

  final Map<String, StreamController<List<Map<String, dynamic>>>> _controllers = {};

  void _initData() {
    // Add some initial mock data
    _tables['profiles'] = [
      {'id': 'mock-user-id', 'full_name': 'Demo User', 'phone': '1234567890'}
    ];
    _tables['vehicles'] = [
      {'id': 'v1', 'user_id': 'mock-user-id', 'name': 'Tesla Model 3', 'type': 'Sedan'},
      {'id': 'v2', 'user_id': 'mock-user-id', 'name': 'BMW X5', 'type': 'SUV'},
    ];
    _tables['bookings'] = [
      {
        'id': 'b1',
        'user_id': 'mock-user-id',
        'vehicle_name': 'Tesla Model 3',
        'vehicle_type': 'Sedan',
        'status': 'confirmed',
        'booking_date': '2024-04-05',
        'booking_time': '10:00 AM',
        'created_at': DateTime.now().toIso8601String(),
      }
    ];
  }

  MockQueryBuilder from(String table) {
    return MockQueryBuilder(table, this);
  }

  Stream<List<Map<String, dynamic>>> getStream(String table, {required List<String> primaryKey}) {
    _controllers.putIfAbsent(table, () => StreamController<List<Map<String, dynamic>>>.broadcast());
    
    // Send initial data
    Timer(Duration.zero, () {
      _controllers[table]?.add(_tables[table] ?? []);
    });
    
    return _controllers[table]!.stream;
  }

  void _notifyChange(String table) {
    _controllers[table]?.add(_tables[table] ?? []);
  }
}

class MockAuth {
  Map<String, dynamic>? _currentUser = {
    'id': 'mock-user-id',
    'phone': '1234567890',
  };

  Map<String, dynamic>? get currentUser => _currentUser;

  Future<void> signInWithOtp({required String phone}) async {
    // Any phone number works in mock
    debugPrint("Mock: Signing in with phone $phone");
  }

  Future<void> verifyOtp({required String phone, required String token, required dynamic type}) async {
    // Any code works in mock
    _currentUser = {
      'id': 'mock-user-id',
      'phone': phone,
    };
  }

  Future<void> signOut() async {
    _currentUser = null;
  }
}

class MockQueryBuilder {
  final String table;
  final MockDatabase db;

  List<Map<String, dynamic>> _workingList = [];
  bool _isSingle = false;
  bool _isMaybeSingle = false;

  // Pending actions
  Map<String, dynamic>? _updateValues;
  bool _isDelete = false;
  dynamic _insertValues;
  bool _isUpsert = false;

  MockQueryBuilder(this.table, this.db) {
    _workingList = List.from(db._tables[table] ?? []);
  }

  MockQueryBuilder select([Object? columns]) {
    return this;
  }

  MockQueryBuilder eq(String column, dynamic value) {
    _workingList = _workingList.where((item) => item[column] == value).toList();
    return this;
  }

  MockQueryBuilder order(String column, {bool ascending = true}) {
    _workingList.sort((a, b) {
      final valA = a[column];
      final valB = b[column];
      if (valA == null || valB == null) return 0;
      return ascending
          ? valA.toString().compareTo(valB.toString())
          : valB.toString().compareTo(valA.toString());
    });
    return this;
  }

  MockQueryBuilder limit(int count) {
    if (_workingList.length > count) {
      _workingList = _workingList.sublist(0, count);
    }
    return this;
  }

  MockQueryBuilder single() {
    _isSingle = true;
    _isMaybeSingle = false;
    return this;
  }

  MockQueryBuilder maybeSingle() {
    _isSingle = true;
    _isMaybeSingle = true;
    return this;
  }

  /// Returns the actual [Future] for this query.
  /// Use this when a real [Future] is required (e.g. in [FutureBuilder]).
  Future<T> build<T>() => _future.then((v) => v as T);

  MockQueryBuilder insert(dynamic values) {
    _insertValues = values;
    return this;
  }

  MockQueryBuilder upsert(dynamic values) {
    _insertValues = values;
    _isUpsert = true;
    return this;
  }

  MockQueryBuilder update(Map<String, dynamic> values) {
    _updateValues = values;
    return this;
  }

  MockQueryBuilder delete() {
    _isDelete = true;
    return this;
  }

  // To simulate the Future response
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  // Future interface
  Future<dynamic> get _future async {
    if (_insertValues != null) {
      if (_isUpsert) {
        final list =
            _insertValues is List
                ? _insertValues as List
                : [_insertValues as Map<String, dynamic>];
        for (var v in list) {
          final id = v['id'];
          if (id != null) {
            final index = db._tables[table]!.indexWhere((e) => e['id'] == id);
            if (index != -1) {
              db._tables[table]![index].addAll(v);
            } else {
              db._tables[table]!.add(v);
            }
          } else {
            final newRow = Map<String, dynamic>.from(v);
            newRow['id'] ??= DateTime.now().millisecondsSinceEpoch.toString();
            newRow['created_at'] ??= DateTime.now().toIso8601String();
            db._tables[table]!.add(newRow);
          }
        }
      } else {
        final list =
            _insertValues is List
                ? _insertValues as List
                : [_insertValues as Map<String, dynamic>];
        for (var v in list) {
          final newRow = Map<String, dynamic>.from(v);
          newRow['id'] ??= DateTime.now().millisecondsSinceEpoch.toString();
          newRow['created_at'] ??= DateTime.now().toIso8601String();
          db._tables[table]!.add(newRow);
        }
      }
      db._notifyChange(table);
      return _insertValues;
    } else if (_updateValues != null) {
      for (var item in _workingList) {
        final index = db._tables[table]!.indexWhere(
          (e) => e['id'] == item['id'],
        );
        if (index != -1) {
          db._tables[table]![index].addAll(_updateValues!);
        }
      }
      db._notifyChange(table);
      return _workingList;
    } else if (_isDelete) {
      final idsToRemove = _workingList.map((e) => e['id']).toList();
      db._tables[table]!.removeWhere(
        (element) => idsToRemove.contains(element['id']),
      );
      db._notifyChange(table);
      return _workingList;
    }

    if (_isSingle) {
      if (_workingList.isEmpty) {
        if (_isMaybeSingle) return null;
        throw Exception("No data found in $table");
      }
      return _workingList.first;
    }
    return _workingList;
  }

  Future<T> then<T>(
    FutureOr<T> Function(dynamic) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);

  // Stream support
  MockStreamBuilder stream({required List<String> primaryKey}) {
    return MockStreamBuilder(
      this,
      db.getStream(table, primaryKey: primaryKey),
    );
  }
}

class MockStreamBuilder extends StreamView<List<Map<String, dynamic>>> {
  final MockQueryBuilder builder;

  MockStreamBuilder(this.builder, Stream<List<Map<String, dynamic>>> stream)
    : super(stream);

  MockStreamBuilder eq(String column, dynamic value) {
    // This is a mock, we don't actually filter the stream yet
    return this;
  }

  MockStreamBuilder order(String column, {bool ascending = true}) {
    return this;
  }

  MockStreamBuilder limit(int count) {
    return this;
  }
}
