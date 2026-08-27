/// A ready-made change-kind enum for surfaces that do not need a bespoke one.
///
/// Prefer declaring your own enum: an exhaustive `switch` over it turns "a new
/// kind has no translation" into a compile error.
enum CommonChangeKind {
  /// A scalar field was edited.
  fieldEdited,

  /// An item was added to a collection.
  itemAdded,

  /// An item was removed from a collection.
  itemRemoved,

  /// An existing item was edited.
  itemEdited,

  /// A quantity was edited.
  quantityChanged,

  /// A price or amount was edited.
  priceChanged,

  /// Attachments were added or removed.
  attachmentsChanged,

  /// A toggle or setting was flipped.
  settingsChanged,

  /// Something changed that no named detector recognised.
  other,
}
