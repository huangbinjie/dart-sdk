part of 'put_parts_task.dart';

/// uploadPart 的返回体
class UploadPart {
  String etag;
  String md5;

  UploadPart({this.etag, this.md5});

  factory UploadPart.fromJson(Map json) {
    return UploadPart(etag: json['etag'], md5: json['md5']);
  }
}

/// 批处理上传 parts 的任务，为 [CompletePartsTask] 提供 [Part]
class UploadPartsTask extends AbstractRequestTask<List<Part>> {
  String token;
  String host;
  String uploadId;
  File file;
  String bucket;
  String key;
  int chunkSize;
  int maxPartsRequestNumber;

  /// 文件 bytes 长度
  int _fileLength;

  /// 每个上传区块的长度
  ///
  /// 文件会按照此长度切片
  int _partLength;

  /// 上传成功后把 part 信息存起来
  final List<Part> _parts = [];

  /// 读文件起始点偏移量
  int _byteStartOffset = 0;

  /// 当前上传到哪一块 chunk
  int _partNumber = 0;

  /// 剩余多少被允许的请求数
  int _idleRequestNumber;

  UploadPartsTask({
    this.token,
    this.host,
    this.chunkSize,
    this.uploadId,
    this.file,
    this.bucket,
    this.key,
    this.maxPartsRequestNumber,
  }) {
    _fileLength = file.lengthSync();
    _partLength = chunkSize * 1024 * 1024;
    _idleRequestNumber = maxPartsRequestNumber;
  }

  @override
  Future<List<Part>> createTask() async {
    final uploadParts = config.cacheProvider.getItem('upload_parts');
    if (uploadParts != null) {
      _parts.addAll(json.decode(uploadParts));
    }
    final com = Completer<List<Part>>();
    _uploadParts(
        () => com.complete(_parts), (error) => com.completeError(error));

    return com.future;
  }

  void _uploadParts(void Function() done, void Function(dynamic) error) {
    /// 超出文件长度说明上传完毕，立即结束
    if (_byteStartOffset >= _fileLength) {
      return;
    }

    do {
      _partNumber++;

      _idleRequestNumber--;

      final uploadedPart = _parts.isNotEmpty
          ? _parts.firstWhere((element) => element.partNumber == _partNumber)
          : null;

      /// 跳过已经上传完成的分片
      if (uploadedPart != null) {
        continue;
      }

      /// 读文件终点偏移量
      final byteEndOffset = _byteStartOffset + _partLength;
      final byteStream = file.openRead(_byteStartOffset, byteEndOffset);

      /// 上传分片(part)的字节大小
      final _byteLength = byteEndOffset > _fileLength
          ? _fileLength - _byteStartOffset
          : _partLength;
      _byteStartOffset += _byteLength;
      final partNumber = _partNumber;

      final task = UploadPartTask(
        token: token,
        host: host,
        bucket: bucket,
        key: key,
        byteLength: _byteLength,
        byteStream: byteStream,
        uploadId: uploadId,
        partNumber: _partNumber,
      );

      task.addProgressListener((sent, total) {
        _sentMap[partNumber] = sent;
        notifyProgress();
      });

      task.future.then((data) {
        _idleRequestNumber++;
        _parts.add(Part(partNumber: partNumber, etag: data.etag));
        if (_parts.length == (_fileLength / _partLength).ceil()) {
          done();
        } else {
          _uploadParts(done, error);
        }
      }).catchError(error);

      manager.addRequestTask(task);
    } while (_idleRequestNumber > 0 && _byteStartOffset < _fileLength);
  }

  /// 已发送的数据记录，key 是 partNumber, value 是 已发送的长度
  final Map<int, int> _sentMap = {};

  void notifyProgress() {
    final _sent = _sentMap.values.reduce((value, element) => value + element);
    notifyProgressListeners(_sent, _fileLength);
  }
}

/// 上传一个 part 的任务
class UploadPartTask<T extends UploadPart> extends AbstractRequestTask<T> {
  String token;
  String host;
  String bucket;
  String key;
  String uploadId;

  /// 字节流的长度
  ///
  /// 如果 data 是 Stream 的话，Dio 需要判断 content-length 才会调用 onSendProgress
  /// https://github.com/flutterchina/dio/blob/21136168ab39a7536835c7a59ce0465bb05feed4/dio/lib/src/dio.dart#L1000
  int byteLength;
  int partNumber;
  Stream<List<int>> byteStream;

  UploadPartTask({
    this.token,
    this.host,
    this.bucket,
    this.key,
    this.uploadId,
    this.byteLength,
    this.byteStream,
    this.partNumber,
  });

  @override
  Future<T> createTask() async {
    final response = await client.put(
        '$host/buckets/$bucket/objects/${base64Url.encode(utf8.encode(key))}/uploads/$uploadId/$partNumber',
        data: byteStream,
        options: Options(headers: {
          Headers.contentLengthHeader: byteLength,
          'Authorization': 'UpToken $token'
        }));

    return UploadPart.fromJson(response.data);
  }
}
