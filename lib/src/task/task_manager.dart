import 'package:meta/meta.dart';
import 'package:qiniu_sdk_base/src/config/config.dart';
import 'abstract_task.dart';
import 'task.dart';

class TaskManager<T extends AbstractTask> {
  @protected
  final List<AbstractTask> workingTasks = [];

  /// 添加一个 [AbstractTask]
  ///
  /// 被添加的 [task] 会被立即执行 [createTask]
  @mustCallSuper
  T addTask(T task) {
    workingTasks.add(task);
    task.preStart();
    task.createTask().then(task.postReceive).catchError(task.postError);
    task.postStart();

    return task;
  }

  @mustCallSuper
  void removeTask(T task) {
    workingTasks.remove(task);
  }

  @mustCallSuper
  void restartTask(T task) {
    task.preRestart();
    task.createTask().then(task.postReceive).catchError(task.postError);
    task.postRestart();
  }
}

class RequestTaskManager<T extends AbstractRequestTask> extends TaskManager {
  Config config;

  RequestTaskManager({this.config});

  T addRequestTask(T task) {
    task.manager = this;
    task.config = config;
    return addTask(task);
  }
}
