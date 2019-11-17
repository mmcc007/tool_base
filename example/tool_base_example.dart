import 'package:tool_base/tool_base.dart';

import 'context_runner.dart';

Future<void> main() {
  return runInContext<void>(() async {
    printTrace('Running in context');
    printStatus('Hello, world!');
  });
}
