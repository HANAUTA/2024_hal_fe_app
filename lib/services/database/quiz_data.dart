import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fe_project/services/database/remote_config.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class QuizData {
  Database? _database;
  String wrongStage = "wrongStage";
  String technologyWrongStage = "テクノロジー系間違えた問題";
  String strategyWrongStage = "ストラテジ系間違えた問題";
  String managementWrongStage = "マネジメント系間違えた問題";

  Future<void> initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'quiz_data.db'); // DBのパスを指定

    //db削除
    // await deleteDatabase(path);

    // ローカルのデータ取得
    _database = await openDatabase(
      path,
      onCreate: (db, version) async {
        // quizDataテーブルの作成
        await db.execute(
          'CREATE TABLE quizData('
          'id INTEGER PRIMARY KEY, '
          'answer TEXT, '
          'comment TEXT, '
          'image TEXT, '
          'link TEXT, '
          'mistake1 TEXT, '
          'mistake2 TEXT, '
          'mistake3 TEXT, '
          'question TEXT, '
          'quiz_id INTEGER, '
          'series_document_id TEXT, '
          'series_name TEXT, '
          'stage_document_id TEXT, '
          'stage_name TEXT, '
          'judge INTEGER'
          ')',
        );
        // appConfigテーブルの作成
        await db.execute(
          'CREATE TABLE appConfig('
          'id INTEGER PRIMARY KEY, '
          'db_version INTEGER'
          ')',
        );
        await db.insert('appConfig', {'id': 1, 'db_version': 0});
      },
      version: 1,
    );
  }

  Future<void> setQuizData({remoteDbVersion}) async {
    await _database!.update('appConfig', {'db_version': remoteDbVersion});

    // Firestoreからdata1, data2, data3のデータを同時に取得
    final snapshots = await Future.wait([
      FirebaseFirestore.instance
          .collection('contents')
          .doc('data')
          .collection('quizzes')
          .doc('data1')
          .get(),
      FirebaseFirestore.instance
          .collection('contents')
          .doc('data')
          .collection('quizzes')
          .doc('data2')
          .get(),
      FirebaseFirestore.instance
          .collection('contents')
          .doc('data')
          .collection('quizzes')
          .doc('data3')
          .get(),
    ]);

    // Firestoreから取得したデータのリストを保持
    List<Map<String, dynamic>> firestoreDataList = [];

    // 各スナップショットからquizDataListを取得し、結合する
    for (var snapshot in snapshots) {
      if (snapshot.exists) {
        // snapshot.data()からquizDataListを取得し、リストに追加
        firestoreDataList.addAll(List.from(snapshot.data()!['quizDataList']));
      }
    }

    // データをSQLiteに保存
    for (var doc in firestoreDataList) {
      // すでにデータが存在するかを確認
      final existingData = await _database!
          .query('quizData', where: 'id = ?', whereArgs: [doc['quiz_id']]);

      if (existingData.isEmpty) {
        // 存在しない場合は新規挿入
        await _database!.insert('quizData', {
          'id': doc['quiz_id'], // Firestoreのデータを使用
          'answer': doc['answer'],
          'comment': doc['comment'],
          'image': doc['image_url'],
          'link': doc['link'],
          'mistake1': doc['mistake_list'][0],
          'mistake2': doc['mistake_list'][1],
          'mistake3': doc['mistake_list'][2],
          'question': doc['question'],
          'quiz_id': doc['quiz_id'],
          'series_document_id': doc['series_document_id'],
          'series_name': doc['series_name'],
          'stage_document_id': doc['stage_document_id'],
          'stage_name': doc['stage_name'],
          'judge': 0, // 初期値
        });
      }
    }
  }

  // クイズデータを取得
  Future<List<Map<String, dynamic>>> getAllQuizData({isFirstLaunch}) async {
    // remote dbバージョン
    int remoteDbVersion = await RemoteConfig().getDbVersion();

    // ローカルdbバージョン
    final appConfig = await _database!.query('appConfig');
    Object? localDbVersion = appConfig[0]['db_version'];

    // remote configのバージョンと違ったらfirebaseから取得
    if (isFirstLaunch && remoteDbVersion != localDbVersion) {
      await setQuizData(remoteDbVersion: remoteDbVersion); // ローカルDBにデータを読み込み
    }

    // DBからクイズデータを取得
    List<Map<String, dynamic>> maps = await _database!.query('quizData');
    return maps;
  }

  Future<List<Map<String, dynamic>>> getTargetQuizData({required targetCategory, int? categoryNum,}) async {
    final List<Map<String, dynamic>> maps;
    if (targetCategory == wrongStage) {
      maps = await _database!.query('quizData', where: 'judge = 1');
    } else if (targetCategory == technologyWrongStage ||
        targetCategory == strategyWrongStage ||
        targetCategory == managementWrongStage) {
      // judgeが1のデータを取得
      maps = await _database!.query('quizData',
          where: 'judge = 1 AND series_document_id LIKE ?',
          whereArgs: ['$categoryNum%']);
    } else {
      maps = await _database!.query('quizData',
          where: 'series_document_id LIKE ?', whereArgs: ['$categoryNum%']);
    }

    return maps;
  }

  // 進捗取得
  Future<Map<String, dynamic>> getProgress({quizDataList}) async {
    int correctAnswersCount =
        quizDataList.where((quiz) => quiz['judge'] == 2).length;
    int wrongAnswersCount =
        quizDataList.where((quiz) => quiz['judge'] == 1).length;
    double correctProgress =
        quizDataList.length > 0 ? correctAnswersCount / quizDataList.length : 0;
    double wrongProgress =
        quizDataList.length > 0 ? wrongAnswersCount / quizDataList.length : 0;
    int totalAnswersCount = correctAnswersCount + wrongAnswersCount;

    return {
      'correctAnswersCount': correctAnswersCount,
      'wrongAnswersCount': wrongAnswersCount,
      'correctProgress': correctProgress,
      'wrongProgress': wrongProgress,
      'totalAnswersCount': totalAnswersCount,
    };
  }

  // クイズデータ進捗リセット
  Future<void> resetProgress() async {
    if (_database == null) {
      print("okasiiyo!!!!!");
    }
    await _database?.update('quizData', {'judge': 0});
  }

  // 正誤判定更新
  void updateJudge({required quizId, required judge}) async {
    await _database!.update('quizData', {'judge': judge},
        where: 'id = ?', whereArgs: [quizId]);
  }
}
