import 'core/converter_tests.dart' as converter_tests;
import 'core/paging_operators_test.dart' as paging_operators_test;
import 'core/query_filter_group_test.dart' as query_filter_group_test;
import 'core/query_filter_test.dart' as query_filter_test;
import 'core/query_metadata_test.dart' as query_metadata_test;
import 'core/query_operation_test.dart' as query_operation_test;
import 'core/query_operators_test.dart' as query_operators_test;
import 'core/query_ordering_test.dart' as query_ordering_test;
import 'core/query_paging_test.dart' as query_paging_test;
import 'core/query_response_test.dart' as query_response_test;
import 'core/query_selections_test.dart' as query_selections_test;
import 'core/query_test.dart' as query_test;

void main() {
  converter_tests.main();
  paging_operators_test.main();
  query_filter_group_test.main();
  query_filter_test.main();
  query_metadata_test.main();
  query_operation_test.main();
  query_ordering_test.main();
  query_response_test.main();
  query_paging_test.main();
  query_selections_test.main();
  query_test.main();
  query_operators_test.main();
}
