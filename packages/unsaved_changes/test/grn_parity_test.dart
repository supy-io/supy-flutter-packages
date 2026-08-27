// Proves each of the five hand-written detectors in the Supy retailer GRN
// screen is expressible as configuration over this package, with the same
// emissions. The fixtures mirror the real fields; only the domain types are
// stand-ins, so the package stays dependency-free.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unsaved_changes/unsaved_changes.dart';

enum GrnChangeKind {
  documentDetails,
  attachments,
  itemsAdded,
  itemsRemoved,
  itemQuantity,
  itemPrice,
  itemDiscount,
  itemPackaging,
  itemDetails,
  charges,
  currency,
  remarks,
  flags,
  unresolvedResolution,
  other,
}

class CartItem {
  CartItem(this.id, this.name);

  final String id;
  String name;
  double? quantity = 1;
  double receivedQty = 1;
  double price = 10;
  double expectedPrice = 10;
  double? adjustment;
  String? packagingId;
  bool hasDraftedPackaging = false;
  String? comment;
  String? taxCode;
  String? locationId;
  double? handlingFee;
  bool physicallyChecked = false;
  bool creditQtyNote = false;
  bool creditPriceNote = false;
  String? creditNoteType;
  bool updatePrice = false;
}

/// Stands in for `GrnChangeSources`.
class GrnSources extends ChangeNotifier {
  // step one
  String documentType = 'invoice';
  String? number = 'INV-1';
  DateTime? date = DateTime(2026);
  DateTime? paymentDueDate;
  double? invoiceAmount = 100;
  bool? paid = false;
  bool? pending = false;
  List<String> attachmentKeys = [];

  // step two
  Map<String, CartItem> cartItems = {};

  // step three — totals
  double? discount;
  String? discountType;
  double? otherFees;
  double? additionalCharges;
  String? currencyCode = 'AED';
  num? currencyRate = 1;

  // step three — settings
  String? remarks;
  bool? dispute = false;
  bool? resolveDispute = false;
  bool? relock = false;
  bool? closeOrder = false;
  bool? updateStock = true;

  // unresolved staging
  Set<String> stagedIds = {};
  Map<String, String> stagedNames = {};

  Map<String, dynamic> payload = {'status': 'draft', 'total': 100};
}

/// The full GRN detector set, as configuration.
List<ChangeDetector<GrnSources, GrnChangeKind>> grnDetectors() => [
      FieldGroupDetector<GrnSources, GrnChangeKind>(
        id: 'document',
        listenablesOf: (s) => [s],
        groups: [
          FieldGroup(
            kind: GrnChangeKind.documentDetails,
            fields: {
              'documentType': (s) => s.documentType,
              'number': (s) => s.number,
              'date': (s) => s.date,
              'paymentDueDate': (s) => s.paymentDueDate,
              'invoiceAmount': (s) => s.invoiceAmount,
              'paid': (s) => s.paid,
              'pending': (s) => s.pending,
            },
          ),
          FieldGroup(
            kind: GrnChangeKind.attachments,
            fields: {'keys': (s) => s.attachmentKeys},
          ),
        ],
      ),
      CollectionDetector<GrnSources, GrnChangeKind, CartItem>(
        id: 'items',
        itemsOf: (s) => s.cartItems,
        subjectOf: (item) => item.name,
        addedKind: GrnChangeKind.itemsAdded,
        removedKind: GrnChangeKind.itemsRemoved,
        listenablesOf: (s) => [s],
        facets: [
          Facet(
            kind: GrnChangeKind.itemQuantity,
            values: (i) => [i.quantity, i.receivedQty],
          ),
          Facet(
            kind: GrnChangeKind.itemPrice,
            values: (i) => [i.price, i.expectedPrice],
          ),
          Facet(
              kind: GrnChangeKind.itemDiscount, values: (i) => [i.adjustment]),
          Facet(
            kind: GrnChangeKind.itemPackaging,
            values: (i) => [i.packagingId, i.hasDraftedPackaging],
          ),
          Facet(
            kind: GrnChangeKind.itemDetails,
            values: (i) => [
              i.comment,
              i.taxCode,
              i.locationId,
              i.handlingFee,
              i.physicallyChecked,
              i.creditQtyNote,
              i.creditPriceNote,
              i.creditNoteType,
              i.updatePrice,
            ],
          ),
        ],
      ),
      FieldGroupDetector<GrnSources, GrnChangeKind>(
        id: 'totals',
        listenablesOf: (s) => [s],
        groups: [
          FieldGroup(
            kind: GrnChangeKind.charges,
            fields: {
              'discount': (s) => s.discount,
              'discountType': (s) => s.discountType,
              'otherFees': (s) => s.otherFees,
              'additionalCharges': (s) => s.additionalCharges,
            },
          ),
          FieldGroup(
            kind: GrnChangeKind.currency,
            fields: {
              'code': (s) => s.currencyCode,
              'rate': (s) => s.currencyRate,
            },
          ),
        ],
      ),
      FieldGroupDetector<GrnSources, GrnChangeKind>(
        id: 'settings',
        listenablesOf: (s) => [s],
        groups: [
          FieldGroup(
            kind: GrnChangeKind.remarks,
            fields: {'remarks': (s) => s.remarks},
            equals: nullableStringEquals,
          ),
          FieldGroup(
            kind: GrnChangeKind.flags,
            fields: {
              'dispute': (s) => s.dispute,
              'resolveDispute': (s) => s.resolveDispute,
              'relock': (s) => s.relock,
              'closeOrder': (s) => s.closeOrder,
              'updateStock': (s) => s.updateStock,
            },
          ),
        ],
      ),
      MembershipDetector<GrnSources, GrnChangeKind>(
        id: 'unresolved',
        kind: GrnChangeKind.unresolvedResolution,
        keysOf: (s) => s.stagedIds,
        subjectOf: (s, key) => s.stagedNames[key as String],
        listenablesOf: (s) => [s],
      ),
      PayloadDigestDetector<GrnSources, GrnChangeKind>(
        id: 'payload-digest',
        kind: GrnChangeKind.other,
        payloadOf: (s) => s.payload,
        volatileKeys: {'status', 'updatePackaging'},
      ),
    ];

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late GrnSources sources;
  late ChangeTracker<GrnSources, GrnChangeKind> tracker;

  setUp(() {
    sources = GrnSources()
      ..cartItems = {
        'a': CartItem('a', 'Tomatoes'),
        'b': CartItem('b', 'Onions'),
      }
      ..stagedNames = {'u1': 'Unknown item'};

    tracker = ChangeTracker<GrnSources, GrnChangeKind>(
      sources: sources,
      detectors: grnDetectors(),
    );
    addTearDown(tracker.dispose);
    addTearDown(sources.dispose);
  });

  Future<void> edit(void Function() change) async {
    change();
    sources.notifyListeners();
    await settle();
  }

  test('a freshly loaded GRN reports nothing', () {
    expect(tracker.hasChanges, isFalse);
    expect(tracker.changeCount, 0);
  });

  test('QA 5: three document fields collapse into one documentDetails',
      () async {
    await edit(() {
      sources
        ..number = 'INV-2'
        ..date = DateTime(2027)
        ..invoiceAmount = 250;
    });

    expect(tracker.changeCount, 1);
    expect(tracker.kinds, {GrnChangeKind.documentDetails});
  });

  test('QA 6: attachments are their own change, and revert cleanly', () async {
    await edit(() => sources.attachmentKeys = ['invoice.pdf']);
    expect(tracker.kinds, {GrnChangeKind.attachments});

    await edit(() => sources.attachmentKeys = []);
    expect(tracker.hasChanges, isFalse);
  });

  test('QA 2: editing a quantity, then reverting it, clears the banner',
      () async {
    await edit(() => sources.cartItems['a']!.quantity = 9);
    expect(tracker.changeCount, 1);
    expect(tracker.changes.changes.single.subject, 'Tomatoes');

    await edit(() => sources.cartItems['a']!.quantity = 1);
    expect(tracker.hasChanges, isFalse);
  });

  test('QA 3: quantity and price on one item are two changes', () async {
    await edit(() {
      sources.cartItems['a']!
        ..quantity = 9
        ..price = 99;
    });

    expect(tracker.changeCount, 2);
    expect(tracker.kinds, {
      GrnChangeKind.itemQuantity,
      GrnChangeKind.itemPrice,
    });
  });

  test('QA 4: adding then removing an item returns to zero', () async {
    await edit(() => sources.cartItems['c'] = CartItem('c', 'Garlic'));
    expect(tracker.kinds, {GrnChangeKind.itemsAdded});

    await edit(() => sources.cartItems.remove('c'));
    expect(tracker.hasChanges, isFalse);
  });

  test('removing a loaded item reports it by name', () async {
    await edit(() => sources.cartItems.remove('b'));

    expect(tracker.changes.changes.single.kind, GrnChangeKind.itemsRemoved);
    expect(tracker.changes.changes.single.subject, 'Onions');
  });

  test('QA 7: currency and charges are separate changes', () async {
    await edit(() => sources.currencyCode = 'USD');
    expect(tracker.kinds, {GrnChangeKind.currency});

    await edit(() => sources.discount = 5);
    expect(tracker.kinds, {GrnChangeKind.currency, GrnChangeKind.charges});
  });

  test('QA 9: several flags collapse into one flags change', () async {
    await edit(() {
      sources
        ..dispute = true
        ..relock = true
        ..closeOrder = true;
    });

    expect(tracker.changeCount, 1);
    expect(tracker.kinds, {GrnChangeKind.flags});
  });

  test('QA 10: typing remarks then clearing to empty reports nothing',
      () async {
    await edit(() => sources.remarks = 'late delivery');
    expect(tracker.kinds, {GrnChangeKind.remarks});

    await edit(() => sources.remarks = '');
    expect(
      tracker.hasChanges,
      isFalse,
      reason: 'null and empty remarks are the same to a user',
    );
  });

  test('QA 8: staging an unresolved resolution reports it by name', () async {
    await edit(() => sources.stagedIds.add('u1'));

    expect(tracker.changes.changes.single.kind,
        GrnChangeKind.unresolvedResolution);
    expect(tracker.changes.changes.single.subject, 'Unknown item');
  });

  test('the payload digest catches an edit no named detector knows', () async {
    await edit(() => sources.payload = {'status': 'draft', 'total': 250});

    expect(tracker.kinds, {GrnChangeKind.other});
  });

  test('the digest never inflates the count for an already-named edit',
      () async {
    await edit(() {
      sources
        ..number = 'INV-2'
        ..payload = {'status': 'draft', 'total': 250};
    });

    expect(
      tracker.changeCount,
      1,
      reason: 'the banner must say "1 unsaved change", not 2',
    );
    expect(tracker.kinds, {GrnChangeKind.documentDetails});
  });

  test('the digest ignores the status the save call sets', () async {
    await edit(() => sources.payload = {'status': 'saved', 'total': 100});

    expect(tracker.hasChanges, isFalse);
  });

  test('QA 11: a successful save re-baselines and clears the banner', () async {
    await edit(() => sources.cartItems['a']!.price = 99);
    expect(tracker.hasChanges, isTrue);

    tracker.captureBaseline();

    expect(tracker.hasChanges, isFalse);
  });

  test('every GRN change kind is reachable through configuration', () async {
    await edit(() {
      sources
        ..number = 'INV-2'
        ..attachmentKeys = ['a.pdf']
        ..discount = 5
        ..currencyCode = 'USD'
        ..remarks = 'note'
        ..dispute = true
        ..stagedIds.add('u1')
        ..cartItems['c'] = CartItem('c', 'Garlic')
        ..cartItems.remove('b');
      sources.cartItems['a']!
        ..quantity = 9
        ..price = 99
        ..adjustment = 2
        ..packagingId = 'p1'
        ..comment = 'bruised';
    });

    expect(tracker.kinds, {
      GrnChangeKind.documentDetails,
      GrnChangeKind.attachments,
      GrnChangeKind.itemsAdded,
      GrnChangeKind.itemsRemoved,
      GrnChangeKind.itemQuantity,
      GrnChangeKind.itemPrice,
      GrnChangeKind.itemDiscount,
      GrnChangeKind.itemPackaging,
      GrnChangeKind.itemDetails,
      GrnChangeKind.charges,
      GrnChangeKind.currency,
      GrnChangeKind.remarks,
      GrnChangeKind.flags,
      GrnChangeKind.unresolvedResolution,
    });
  });
}
