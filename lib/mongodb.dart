import 'constant.dart';
import 'package:mongo_dart/mongo_dart.dart';

class MongoDatabase {
  static late Db _db;
  static late DbCollection _collection;
  static late DbCollection _historyCollection;

  static Future<void> connect() async {
    _db = await Db.create(MONGO_URL);
    await _db.open();
    _collection = _db.collection(COLLECTION_NAME);
    _historyCollection = _db.collection('History');
  }

  Future<bool> isUsernameTaken(String username) async {
    var user = await _collection.findOne(where.eq('username', username));
    return user != null;
  }

  Future<void> registerUser(String username, String password) async {
    await _collection.insertOne({'username': username, 'password': password});
  }

  Future<bool> loginUser(String username, String password) async {
    var user = await _collection.findOne(where
        .eq('username', username)
        .eq('password', password));
    return user != null;
  }


  Future<bool> isWeightSavedForToday(DateTime date) async {
    String today = "${date.year}-${date.month}-${date.day}";
    var record = await _historyCollection.findOne(where.eq('date', today));
    return record != null;
  }

  Future<void> saveWeightForToday(double weight) async {
    String today = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    await _historyCollection.insertOne({'date': today, 'weight': weight});
  }

  Future<List<Map<String, dynamic>>> getWeightHistory() async {
    // Get today's date
    DateTime today = DateTime.now();

    // Calculate the date 7 days ago
    DateTime sevenDaysAgo = today.subtract(Duration(days: 7));

    // Query the collection for the last 7 days, sorted in descending order by date
    return await _historyCollection
        .find(where
        .gte('date', sevenDaysAgo.toIso8601String().substring(0, 10)) // Filter from 7 days ago
        .sortBy('date', descending: true) // Sort by date in descending order
        .limit(7)) // Limit to 7 documents
        .toList();
  }

  Future<double?> getYesterdayWeight() async {
    String yesterday = "${DateTime.now().subtract(Duration(days: 1)).year}-${DateTime.now().subtract(Duration(days: 1)).month}-${DateTime.now().subtract(Duration(days: 1)).day}";
    var record = await _historyCollection.findOne(where.eq('date', yesterday));
    return record != null ? record['weight'] : null;
  }
}
