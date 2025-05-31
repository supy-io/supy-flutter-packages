part of 'cart_options.dart';

/// Controls cart session lifetime and expiration behavior.
class SessionOptions {
  /// Creates a new instance of [SessionOptions] with optional parameters.
  SessionOptions({
    this.expiresIn,
    this.warningThreshold,
    this.onSessionExpire,
    this.autoExtendOnActivity = false,
    this.maxIdleTime,
    this.onSessionWarning,
    this.warningBeforeExpiry,
    this.persistSession = true,
    this.onSessionStart,
    this.onSessionExtend,
    this.maxSessionDuration,
    this.sessionId,
    this.enableSessionMetrics = false,
    this.customMetadata,
  });

  /// Duration until a cart session expires.
  Duration? expiresIn;

  /// Duration after which a warning is triggered before expiration.
  Duration? warningThreshold;

  /// Callback to execute when a session expires.
  final void Function()? onSessionExpire;

  /// Whether to automatically extend session on user activity.
  final bool autoExtendOnActivity;

  /// Maximum idle time before session expires (overrides expiresIn if shorter).
  Duration? maxIdleTime;

  /// Callback to execute before session expires (warning).
  final void Function(Duration timeRemaining)? onSessionWarning;

  /// Duration before expiry to trigger warning callback.
  Duration? warningBeforeExpiry;

  /// Whether to persist session data across app restarts.
  final bool persistSession;

  /// Callback to execute when a new session starts.
  final void Function(String sessionId)? onSessionStart;

  /// Callback to execute when session is extended.
  final void Function(Duration newExpiryTime)? onSessionExtend;

  /// Absolute maximum session duration (even with extensions).
  Duration? maxSessionDuration;

  /// Custom session identifier. If null, one will be generated.
  String? sessionId;

  /// Whether to collect session metrics (duration, extensions, etc.).
  final bool enableSessionMetrics;

  /// Custom metadata to associate with the session.
  final Map<String, dynamic>? customMetadata;

  /// Determines whether the session has expired since [createdAt].
  bool isExpired(DateTime createdAt, {DateTime? lastActivity}) {
    final now = DateTime.now();

    // Check absolute expiration
    if (expiresIn != null && now.difference(createdAt) > expiresIn!) {
      return true;
    }

    // Check idle timeout
    if (maxIdleTime != null && lastActivity != null) {
      if (now.difference(lastActivity) > maxIdleTime!) {
        return true;
      }
    }

    // Check maximum session duration
    if (maxSessionDuration != null &&
        now.difference(createdAt) > maxSessionDuration!) {
      return true;
    }

    return false;
  }

  /// Determines if a warning should be triggered.
  bool shouldWarn(DateTime createdAt, {DateTime? lastActivity}) {
    if (warningBeforeExpiry == null) return false;

    final now = DateTime.now();

    if (expiresIn != null) {
      final timeUntilExpiry = expiresIn! - now.difference(createdAt);
      return timeUntilExpiry <= warningBeforeExpiry! &&
          timeUntilExpiry > Duration.zero;
    }

    return false;
  }

  /// Gets the time remaining before session expires.
  Duration? getTimeRemaining(DateTime createdAt, {DateTime? lastActivity}) {
    if (isExpired(createdAt, lastActivity: lastActivity)) {
      return Duration.zero;
    }

    final now = DateTime.now();
    Duration? shortestRemaining;

    // Check regular expiration
    if (expiresIn != null) {
      final remaining = expiresIn! - now.difference(createdAt);
      shortestRemaining = remaining;
    }

    // Check idle timeout
    if (maxIdleTime != null && lastActivity != null) {
      final idleRemaining = maxIdleTime! - now.difference(lastActivity);
      if (shortestRemaining == null || idleRemaining < shortestRemaining) {
        shortestRemaining = idleRemaining;
      }
    }

    // Check maximum session duration
    if (maxSessionDuration != null) {
      final maxRemaining = maxSessionDuration! - now.difference(createdAt);
      if (shortestRemaining == null || maxRemaining < shortestRemaining) {
        shortestRemaining = maxRemaining;
      }
    }

    return shortestRemaining;
  }

  /// Creates a copy of this [SessionOptions] with the specified parameters.
  SessionOptions copyWith({
    Duration? expiresIn,
    Duration? warningThreshold,
    void Function()? onSessionExpire,
    bool? autoExtendOnActivity,
    Duration? maxIdleTime,
    void Function(Duration)? onSessionWarning,
    Duration? warningBeforeExpiry,
    bool? persistSession,
    void Function(String)? onSessionStart,
    void Function(Duration)? onSessionExtend,
    Duration? maxSessionDuration,
    String? sessionId,
    bool? enableSessionMetrics,
    Map<String, dynamic>? customMetadata,
  }) {
    return SessionOptions(
      expiresIn: expiresIn ?? this.expiresIn,
      warningThreshold: warningThreshold ?? this.warningThreshold,
      onSessionExpire: onSessionExpire ?? this.onSessionExpire,
      autoExtendOnActivity: autoExtendOnActivity ?? this.autoExtendOnActivity,
      maxIdleTime: maxIdleTime ?? this.maxIdleTime,
      onSessionWarning: onSessionWarning ?? this.onSessionWarning,
      warningBeforeExpiry: warningBeforeExpiry ?? this.warningBeforeExpiry,
      persistSession: persistSession ?? this.persistSession,
      onSessionStart: onSessionStart ?? this.onSessionStart,
      onSessionExtend: onSessionExtend ?? this.onSessionExtend,
      maxSessionDuration: maxSessionDuration ?? this.maxSessionDuration,
      sessionId: sessionId ?? this.sessionId,
      enableSessionMetrics: enableSessionMetrics ?? this.enableSessionMetrics,
      customMetadata: customMetadata ?? this.customMetadata,
    );
  }
}
