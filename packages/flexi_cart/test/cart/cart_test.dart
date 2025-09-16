import 'cart_clone_cast_test.dart' as cart_clone_cast_test;
import 'cart_core_test.dart' as cart_core_test;
import 'cart_currency_test.dart' as cart_currency_test;
import 'cart_disposed_test.dart' as cart_disposed_test;
import 'cart_expiration_test.dart' as cart_expiration_test;
import 'cart_history_test.dart' as cart_history_test;
import 'cart_item_test.dart' as cart_item_test;
import 'cart_items_group_test.dart' as cart_items_group_test;
import 'cart_lock_test.dart' as cart_lock_test;
import 'cart_metadata_test.dart' as cart_metadata_test;
import 'cart_options/cart_options_test.dart' as cart_options_test;
import 'cart_plugins_test.dart' as cart_plugins_test;
import 'cart_reset_test.dart' as cart_reset_test;
import 'cart_shared_prefs_test.dart' as cart_shared_prefs_test;

void main() {
  cart_reset_test.main();
  cart_plugins_test.main();
  cart_metadata_test.main();
  cart_lock_test.main();
  cart_items_group_test.main();
  cart_item_test.main();
  cart_expiration_test.main();
  cart_disposed_test.main();
  cart_currency_test.main();
  cart_clone_cast_test.main();
  cart_core_test.main();
  cart_history_test.main();
  cart_options_test.main();
  cart_shared_prefs_test.main();
}
