import 'base/common_test.dart' as common_test;
import 'base/config_test.dart' as config_test;
import 'base/context_test.dart' as context_test;
import 'base/file_system_test.dart' as file_system_test;
import 'base/io_test.dart' as io_test;
import 'base/logger_test.dart' as logger_test;
import 'base/net_test.dart' as net_test;
import 'base/os_test.dart' as os_test;
import 'base/os_utils_test.dart' as os_utils_test;
import 'base/process_test.dart' as process_test;
import 'base/terminal_test.dart' as terminal_test;
import 'cache_test.dart' as cache_test;

void main() {
  cache_test.main();
  common_test.main();
  config_test.main();
  context_test.main();
  file_system_test.main();
  io_test.main();
  logger_test.main();
  net_test.main();
  os_test.main();
  os_utils_test.main();
  process_test.main();
  terminal_test.main();
}
