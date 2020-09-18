abstract class AbstractRegionProvider<T> {
  String getHostByRegion(T region);

  Future<String> getHostByToken(String token, [Protocol protocol]);
}

class RegionProvider extends AbstractRegionProvider<Region> {
  @override
  String getHostByRegion(region) {
    return Protocol.Https.value + '://' + region.host;
  }

  @override
  Future<String> getHostByToken(String token,
      [Protocol protocol = Protocol.Http]) {
    return getHostByToken(token, protocol);
  }
}

enum Region { Z0, Z1, Z2, Na0, As0 }

extension RegionExt on Region {
  String get host {
    switch (this) {
      case Region.Z0:
        return 'upload.qiniup.com';
      case Region.Z1:
        return 'upload-z1.qiniup.com';
      case Region.Z2:
        return 'upload-z2.qiniup.com';
      case Region.Na0:
        return 'upload-na0.qiniup.com';
      case Region.As0:
        return 'upload-as0.qiniup.com';
      default:
        return 'upload.qiniup.com';
    }
  }
}

enum Protocol { Http, Https }

extension ProtocolExt on Protocol {
  String get value {
    if (this == Protocol.Http) return 'http';
    if (this == Protocol.Https) return 'https';
    return 'https';
  }
}
