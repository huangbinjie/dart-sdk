import 'package:dio/dio.dart';
import 'package:qiniu_sdk_base/src/auth/auth.dart';

part 'protocol.dart';
part 'host.dart';
part 'cache.dart';

class Config {
  AbstractHostProvider hostProvider;
  AbstractCacheProvider cacheProvider;

  Config({
    this.hostProvider,
    this.cacheProvider,
  }) {
    hostProvider = hostProvider ?? HostProvider();
    cacheProvider = cacheProvider ?? CacheProvider();
  }
}
