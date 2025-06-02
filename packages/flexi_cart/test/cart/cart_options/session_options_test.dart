// import 'package:flexi_cart/flexi_cart.dart';
// import 'package:flutter_test/flutter_test.dart';
//
// import '../../flexi_cart_test.dart';
//
// void main() {
//   group('FlexiCart Session Management Tests', () {
//     late FlexiCart<MockCartItem> cart;
//     late SessionOptions sessionOptions;
//
//     setUp(() {
//       sessionOptions = SessionOptions(
//         expiresIn: const Duration(minutes: 30),
//         warningThreshold: const Duration(minutes: 5),
//         autoExtendOnActivity: true,
//         enableSessionMetrics: true,
//       );
//
//       cart = FlexiCart<MockCartItem>(
//         options: CartOptions(sessionOptions: sessionOptions),
//       );
//     });
//
//     tearDown(() {
//       cart.dispose();
//     });
//
//     group('Session Initialization', () {
//       test('should initialize session with default values', () {
//         expect(cart.sessionId, isNotEmpty);
//         expect(cart.sessionCreatedAt, isNotNull);
//         expect(cart.lastActivity, isNotNull);
//         expect(cart.sessionExtensions, equals(0));
//         expect(cart.isSessionExpired, isFalse);
//       });
//
//       test('should use custom session ID when provided', () {
//         const customId = 'custom_session_123';
//         final customOptions = SessionOptions(
//           sessionId: customId,
//           expiresIn: const Duration(minutes: 30),
//         );
//
//         final customCart = FlexiCart<MockCartItem>(
//           options: CartOptions(sessionOptions: customOptions),
//         );
//
//         expect(customCart.sessionId, equals(customId));
//         customCart.dispose();
//       });
//
//       test('should generate unique session IDs', () {
//         final cart1 = FlexiCart<MockCartItem>(
//           options: CartOptions(
//             sessionOptions: SessionOptions(
//               expiresIn: const Duration(minutes: 30),
//             ),
//           ),
//         );
//         final cart2 = FlexiCart<MockCartItem>(
//           options: CartOptions(
//             sessionOptions: SessionOptions(
//               expiresIn: const Duration(minutes: 30),
//             ),
//           ),
//         );
//
//         expect(cart1.sessionId, isNot(equals(cart2.sessionId)));
//         cart1.dispose();
//         cart2.dispose();
//       });
//     });
//
//     group('Session Expiration', () {
//       test('should detect expired session', () async {
//         final shortSessionCart = FlexiCart<MockCartItem>(
//           options: CartOptions(
//             sessionOptions: SessionOptions(
//               expiresIn: const Duration(milliseconds: 10),
//             ),
//           ),
//         );
//
//         await Future<void>.delayed(
//           const Duration(milliseconds: 20),
//         );
//         expect(shortSessionCart.isSessionExpired, isTrue);
//         shortSessionCart.dispose();
//       });
//
//       test('should manually expire session', () {
//         cart.expireSession();
//         expect(cart.isSessionExpired, isTrue);
//         expect(cart.getSessionTimeRemaining(), isNull);
//       });
//
//       test('should call onSessionExpire callback', () {
//         var called = false;
//
//         final testCart = FlexiCart<MockCartItem>(
//           options: CartOptions(
//             sessionOptions: SessionOptions(
//               expiresIn: const Duration(minutes: 30),
//               onSessionExpire: () => called = true,
//             ),
//           ),
//         )..expireSession();
//         expect(called, isTrue);
//         testCart.dispose();
//       });
//     });
//
//     group('Session Extension', () {
//       test('should extend session and update activity', () async {
//         final initialExtensions = cart.sessionExtensions;
//         await Future<void>.delayed(const Duration(milliseconds: 5));
//         cart.extendSession();
//
//         expect(cart.sessionExtensions, equals(initialExtensions + 1));
//       });
//
//       test('should call onSessionExtend callback', () {
//         Duration? remaining;
//
//         final testCart = FlexiCart<MockCartItem>(
//           options: CartOptions(
//             sessionOptions: SessionOptions(
//               expiresIn: const Duration(minutes: 30),
//               onSessionExtend: (r) => remaining = r,
//             ),
//           ),
//         )..extendSession();
//         expect(remaining, isNotNull);
//         testCart.dispose();
//       });
//     });
//
//     group('Session Warnings', () {
//       test('should trigger warning logic based on threshold', () {
//         final warnCart = FlexiCart<MockCartItem>(
//           options: CartOptions(
//             sessionOptions: SessionOptions(
//               expiresIn: const Duration(minutes: 10),
//               warningThreshold: const Duration(minutes: 9),
//             ),
//           ),
//         );
//
//         final shouldWarn = warnCart.options.sessionOptions.shouldWarn(
//           warnCart.sessionCreatedAt,
//           lastActivity: warnCart.lastActivity,
//         );
//
//         expect(shouldWarn, isTrue);
//         warnCart.dispose();
//       });
//     });
//
//     group('Session Metrics', () {
//       test('should return session metrics', () {
//         final metrics = cart.getSessionMetrics();
//
//         expect(metrics, containsPair('sessionId', cart.sessionId));
//         expect(metrics, contains('createdAt'));
//         expect(metrics, contains('extensions'));
//         expect(metrics, contains('isExpired'));
//       });
//
//       test('should return empty metrics when disabled', () {
//         final noMetricsCart = FlexiCart<MockCartItem>(
//           options: CartOptions(
//             sessionOptions: SessionOptions(
//               expiresIn: const Duration(minutes: 30),
//             ),
//           ),
//         );
//
//         expect(noMetricsCart.getSessionMetrics(), isEmpty);
//         noMetricsCart.dispose();
//       });
//     });
//
//     group('Session Callbacks', () {
//       test('should call onSessionStart', () {
//         String? id;
//         final testCart = FlexiCart<MockCartItem>(
//           options: CartOptions(
//             sessionOptions: SessionOptions(
//               onSessionStart: (sessionId) => id = sessionId,
//             ),
//           ),
//         );
//
//         expect(id, equals(testCart.sessionId));
//         testCart.dispose();
//       });
//     });
//   });
//
//   group('SessionOptions Unit Tests', () {
//     test('should create SessionOptions with defaults', () {
//       final options = SessionOptions();
//       expect(options.expiresIn, isNull);
//       expect(options.warningThreshold, isNull);
//       expect(options.autoExtendOnActivity, isFalse);
//     });
//
//     test('should calculate expiration correctly', () {
//       final now = DateTime.now();
//       final options = SessionOptions(
//         expiresIn: const Duration(minutes: 5),
//       );
//       final createdAt = now.subtract(
//         const Duration(minutes: 6),
//       );
//       expect(options.isExpired(createdAt), isTrue);
//     });
//
//     test('should get time remaining', () {
//       final now = DateTime.now();
//       final options = SessionOptions(
//         expiresIn: const Duration(minutes: 30),
//       );
//       final createdAt = now.subtract(
//         const Duration(minutes: 10),
//       );
//       final remaining = options.getTimeRemaining(createdAt);
//       expect(
//         remaining!.inMinutes,
//         closeTo(20, 2),
//       );
//     });
//
//     test('should warn correctly', () {
//       final now = DateTime.now();
//       final options = SessionOptions(
//         expiresIn: const Duration(minutes: 30),
//         warningThreshold: const Duration(minutes: 5),
//       );
//
//       final createdAt = now.subtract(
//         const Duration(minutes: 26),
//       );
//       expect(options.shouldWarn(createdAt), isTrue);
//     });
//   });
// }
