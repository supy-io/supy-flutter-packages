import 'package:flexi_cart/flexi_cart.dart';
import 'package:mocktail/mocktail.dart';

class MockCallbackFunction extends Mock {
  void call();
}

class MockItem extends ICartItem {
  MockItem({
    required super.id,
    required super.name,
    required super.price,
    super.quantity = 1,
    this.groupId = 'default',
    this.groupNameVal = 'Default Group',
  });

  final String groupId;
  final String groupNameVal;

  @override
  String get key => id;

  @override
  String get group => groupId;

  @override
  String get groupName => groupNameVal;

  @override
  double totalPrice() => notNullQty() * price;
}

class MockCartItem extends Mock implements ICartItem {}

class MockCartItem2 extends MockCartItem {}

class CartItem extends ICartItem {
  CartItem({
    required super.price,
    required super.id,
    required super.name,
    required super.currency,
    super.groupName,
    super.image,
    super.unit = '',
    super.quantity = 0,
  });
}

class TestPlugin<T extends ICartItem> implements ICartPlugin<T> {
  Map<String, bool> calledMap = {
    'onChange': false,
    'onClose': false,
    'onError': false,
  };

  @override
  void onChange(FlexiCart<T> cart) => calledMap['onChange'] = true;

  @override
  void onClose(FlexiCart<T> cart) => calledMap['onClose'] = true;

  @override
  void onError(FlexiCart<T> cart, Object error, StackTrace stackTrace) =>
      calledMap['onError'] = true;
}
