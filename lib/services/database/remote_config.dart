import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfig {
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  // remote configからdbバージョンを取得する
  Future<int> getDbVersion() async {

    // remote config設定
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: Duration.zero,
    ));

    // set default　いるのかわからない
    await remoteConfig.setDefaults(<String, dynamic>{
      "db_version": 0,
    });

    // remote dbバージョン取得
    await remoteConfig.fetchAndActivate();
    int remoteDbVersion = remoteConfig.getInt("db_version");
    
    return remoteDbVersion;
  }
}