import 'package:flutter_test/flutter_test.dart';
import 'package:unsaved_changes/unsaved_changes.dart';

enum Cart { added, removed, quantity, price, details }

/// Deliberately mutable, so the mutate-in-place test is realistic.
class Line {
  Line(this.id, this.name, {this.qty = 1, this.price = 0, this.note});

  final String id;
  String name;
  double qty;
  double price;
  String? note;
}

class Basket {
  Basket(this.lines);

  Map<String, Line> lines;
}

void main() {
  late Basket basket;

  setUp(
    () => basket = Basket({
      'a': Line('a', 'Tomatoes', qty: 2, price: 5),
      'b': Line('b', 'Onions', price: 3),
    }),
  );

  CollectionDetector<Basket, Cart, Line> build() =>
      CollectionDetector<Basket, Cart, Line>(
        id: 'items',
        itemsOf: (b) => b.lines,
        subjectOf: (line) => line.name,
        addedKind: Cart.added,
        removedKind: Cart.removed,
        facets: [
          Facet(kind: Cart.quantity, values: (line) => [line.qty]),
          Facet(kind: Cart.price, values: (line) => [line.price]),
          Facet(kind: Cart.details, values: (line) => [line.note]),
        ],
      );

  test('reports nothing while the collection matches', () {
    final session = build().start(basket);

    expect(session.diff(basket), isEmpty);
  });

  test('reports an added item by name', () {
    final session = build().start(basket);

    basket.lines['c'] = Line('c', 'Garlic');

    final changes = session.diff(basket).toList();
    expect(changes, hasLength(1));
    expect(changes.single.kind, Cart.added);
    expect(changes.single.subject, 'Garlic');
  });

  test('reports a removed item by the name it had at baseline', () {
    final session = build().start(basket);

    basket.lines.remove('a');

    final changes = session.diff(basket).toList();
    expect(changes, hasLength(1));
    expect(changes.single.kind, Cart.removed);
    expect(changes.single.subject, 'Tomatoes');
  });

  test('reports one change per moved facet, not per field', () {
    final session = build().start(basket);

    basket.lines['a']!
      ..qty = 9
      ..price = 50;

    final changes = session.diff(basket).toList();
    expect(changes.map((c) => c.kind), [Cart.quantity, Cart.price]);
    expect(changes.every((c) => c.subject == 'Tomatoes'), isTrue);
  });

  test('an item mutated in place cannot rewrite its own baseline', () {
    final session = build().start(basket);

    basket.lines['a']!.qty = 42;

    expect(
      session.diff(basket).map((c) => c.kind),
      [Cart.quantity],
      reason: 'the snapshot must hold extracted values, not the live object',
    );
  });

  test('stops reporting when a value is edited back', () {
    final session = build().start(basket);

    basket.lines['a']!.qty = 9;
    expect(session.diff(basket), hasLength(1));

    basket.lines['a']!.qty = 2;
    expect(session.diff(basket), isEmpty);
  });

  test('omitting addedKind and removedKind ignores membership', () {
    final detector = CollectionDetector<Basket, Cart, Line>(
      id: 'items',
      itemsOf: (b) => b.lines,
      subjectOf: (line) => line.name,
      facets: [
        Facet(kind: Cart.quantity, values: (line) => [line.qty])
      ],
    );
    final session = detector.start(basket);

    basket.lines
      ..remove('a')
      ..['c'] = Line('c', 'Garlic');

    expect(session.diff(basket), isEmpty);
  });

  test('a facet subject overrides the item name', () {
    final detector = CollectionDetector<Basket, Cart, Line>(
      id: 'items',
      itemsOf: (b) => b.lines,
      subjectOf: (line) => line.name,
      facets: [
        Facet(
          kind: Cart.quantity,
          values: (line) => [line.qty],
          subject: 'Quantities',
        ),
      ],
    );
    final session = detector.start(basket);

    basket.lines['a']!.qty = 9;
    expect(session.diff(basket).single.subject, 'Quantities');
  });

  test('renaming an item keeps its identity via the key', () {
    final session = build().start(basket);

    basket.lines['a']!.name = 'Cherry tomatoes';

    expect(
      session.diff(basket),
      isEmpty,
      reason: 'the name is a label, not part of any facet',
    );
  });

  test('the keyed factory derives keys from the items themselves', () {
    final detector = CollectionDetector<Basket, Cart, Line>.keyed(
      id: 'items',
      itemsOf: (b) => b.lines.values,
      keyOf: (line) => line.id,
      subjectOf: (line) => line.name,
      addedKind: Cart.added,
      facets: [
        Facet(kind: Cart.quantity, values: (line) => [line.qty])
      ],
    );
    final session = detector.start(basket);

    basket.lines['c'] = Line('c', 'Garlic');

    expect(session.diff(basket).single.kind, Cart.added);
  });
}
