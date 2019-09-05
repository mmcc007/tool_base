[![pub package](https://img.shields.io/pub/v/tool_base.svg)](https://pub.dartlang.org/packages/tool_base)
[![Build Status](https://travis-ci.com/mmcc007/tool_base.svg?branch=master)](https://travis-ci.com/mmcc007/tool_base)
[![codecov](https://codecov.io/gh/mmcc007/tool_base/branch/master/graph/badge.svg)](https://codecov.io/gh/mmcc007/tool_base)

A library for Dart developers.

## Usage

A simple usage example:

```dart
import 'package:tool_base/tool_base.dart';

import 'context_runner.dart';

main() {
  return runInContext<void>(() async {
    printTrace('Running in context');
    printStatus('Hello, world!');
  });
}
```

See [example](example) for details.

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme
