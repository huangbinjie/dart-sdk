import 'package:qiniu_sdk_base/src/config.dart';
import 'package:test/test.dart';

import 'token.dart';

void main() {
  test('RegionProvider should works well.', () async {
    final regionProvider = RegionProvider();
    final zoHost = regionProvider.getHostByRegion(Region.Z0);

    expect(zoHost, 'https://upload.qiniup.com');

    final hostInToken = await regionProvider.getHostByToken(token);

    // 根据传入的 token 的 bucket 对应的区域，需要对应的修改这里
    expect(hostInToken, Region.Z2.host);
  });
}
