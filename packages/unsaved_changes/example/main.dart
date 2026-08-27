import 'package:flutter/material.dart';
import 'package:unsaved_changes/unsaved_changes.dart';

/// What the detectors read from.
class ProfileForm {
  ProfileForm({required this.name, required this.email});

  final TextEditingController name;
  final TextEditingController email;
}

/// This surface's own change kinds. An exhaustive `switch` when describing
/// them means a new kind cannot ship without a translation.
enum ProfileChange { name, email }

class ProfileDetector
    extends SnapshotChangeDetector<List<String>, ProfileForm, ProfileChange> {
  const ProfileDetector();

  @override
  String get id => 'profile';

  @override
  List<String> capture(ProfileForm form) => [form.name.text, form.email.text];

  @override
  Iterable<TrackedChange<ProfileChange>> compare(
    List<String> baseline,
    ProfileForm form,
  ) =>
      [
        if (form.name.text != baseline[0])
          const TrackedChange(ProfileChange.name, subject: 'Name'),
        if (form.email.text != baseline[1])
          const TrackedChange(ProfileChange.email, subject: 'Email'),
      ];

  @override
  Iterable<Listenable> listenables(ProfileForm form) => [form.name, form.email];
}

void main() {
  final form = ProfileForm(
    name: TextEditingController(text: 'Ada'),
    email: TextEditingController(text: 'ada@example.com'),
  );

  final tracker = ChangeTracker<ProfileForm, ProfileChange>(
    sources: form,
    detectors: const [ProfileDetector()],
  )..addListener(() {});

  // Edit something, and after the next microtask the tracker reports it.
  form.name.text = 'Ada Lovelace';

  // Guard a back navigation with `tracker.hasChanges`, show a banner with
  // `tracker.changeCount`, and call `tracker.captureBaseline()` after a
  // successful save.
  debugPrint(tracker.describe());
}
