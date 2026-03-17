// ============================================================================
// 4️⃣ ERROR HANDLING & USER FEEDBACK
// ============================================================================

// ignore_for_file: avoid_print, use_super_parameters

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';


/// Base class for all app errors.
abstract class SkyMapException implements Exception {
  final String message;
  final String? title;
  final String? action;

  SkyMapException({
    required this.message,
    this.title,
    this.action,
  });

  @override
  String toString() => message;
}

/// Location/GPS error.
class LocationException extends SkyMapException {
  LocationException({
    required String message,
    String? title,
    String? action,
  }) : super(
    message: message,
    title: title ?? 'Location error',
    action: action ?? 'Try again',
  );
}

/// Location services are disabled.
class LocationServiceDisabledException extends LocationException {
  LocationServiceDisabledException()
      : super(
    message:
        'Location services are disabled on your device.\n\n'
        'To allow Sky Map to determine your sky correctly, '
        'enable Location Services in Settings.',
    title: 'Location services disabled',
    action: 'Open Settings',
  );
}

/// Location permission permanently denied.
class LocationPermissionDeniedForeverException extends LocationException {
  LocationPermissionDeniedForeverException()
      : super(
    message:
        'Location permission has been permanently denied.\n\n'
        'To grant permission:\n'
        '1. Open Settings\n'
        '2. Sky Map > Location\n'
        '3. Choose "Always" or "While Using the App".',
    title: 'Location permission denied',
    action: 'Open Settings',
  );
}

/// Location permission temporarily denied.
class LocationPermissionDeniedTemporaryException extends LocationException {
  LocationPermissionDeniedTemporaryException()
      : super(
    message:
        'You did not grant location permission.\n\n'
        'Sky Map needs location access to work properly.',
    title: 'Permission not granted',
    action: 'Try again',
  );
}

/// Sensor error.
class SensorException extends SkyMapException {
  SensorException({
    required String message,
    String? title,
    String? action,
  }) : super(
    message: message,
    title: title ?? 'Sensor error',
    action: action,
  );
}

/// Sensor is not available on this device.
class SensorNotAvailableException extends SensorException {
  final String sensorName;

  SensorNotAvailableException(this.sensorName)
      : super(
    message:
        'The "$sensorName" sensor is not available on your device.\n\n'
        'Sky Map can still run with limited functionality, '
        'but orientation may be inaccurate.',
    title: '$sensorName not available',
    action: 'OK',
  );
}

/// Magnetometer calibration is needed.
class SensorCalibrationException extends SensorException {
  SensorCalibrationException()
      : super(
    message:
        'The magnetometer needs calibration.\n\n'
        'To calibrate:\n'
        '1. Move your device in a figure-eight motion\n'
        '2. Rotate it in all directions\n'
        '3. Wait 10–15 seconds',
    title: 'Magnetometer calibration',
    action: 'Start',
  );
}

/// API/Network error.
class NetworkException extends SkyMapException {
  NetworkException({
    required String message,
    String? title,
    String? action,
  }) : super(
    message: message,
    title: title ?? 'Network error',
    action: action ?? 'Try again',
  );
}

/// Failed to fetch data for celestial objects.
class DataFetchException extends NetworkException {
  DataFetchException(String source)
      : super(
    message:
        'Unable to load data from $source.\n\n'
        'Sky Map will use built-in default descriptions.\n\n'
        'Please check your internet connection.',
    title: 'Could not load data',
    action: 'Try again',
  );
}

/// Error during astronomical calculations.
class AstronomicalCalculationException extends SkyMapException {
  AstronomicalCalculationException(String detail)
      : super(
    message:
        'An error occurred while calculating celestial object positions.\n\n'
        'Details: $detail',
    title: 'Calculation error',
    action: 'Report',
  );
}

/// Unknown error.
class UnknownException extends SkyMapException {
  final Exception? originalException;
  final StackTrace? stackTrace;

  UnknownException({
    required String message,
    this.originalException,
    this.stackTrace,
  }) : super(
    message: message,
    title: 'Unknown error',
    action: 'Report',
  );
}

// ============================================================================
// ERROR HANDLER CLASSES
// ============================================================================

/// Location error handler.
class LocationErrorHandler {
  /// Get position with friendly error handling.
  static Future<Position?> getPositionWithErrorHandling() async {
    try {
      // Check whether location services are enabled.
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        throw LocationServiceDisabledException();
      }

      // Check permission.
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionDeniedForeverException();
      }

      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedTemporaryException();
      }

      // Get position.
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 30),
      );

      print('✅ Location acquired: ${position.latitude}, ${position.longitude}');
      return position;
    } on LocationException {
      rethrow; // Re-throw our domain exception.
    } catch (e, stackTrace) {
      print('❌ Unknown error while getting location: $e');
      print(stackTrace);
      throw UnknownException(
        message: 'Unable to get your location.\n\nError: $e',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  /// Listen for location updates with error handling.
  static Stream<Position> getPositionStreamWithErrorHandling() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).handleError((e) {
      print('❌ Location stream error: $e');
      return null;
    });
  }

  /// Get a user-friendly location error description.
  static String getLocationErrorDescription(dynamic error) {
    if (error is LocationException) {
      return error.message;
    }
    return 'Location error: $error';
  }
}

/// Sensor error handler.
class SensorErrorHandler {
  /// Initialize sensors with basic verification.
  static Future<bool> initializeSensorsWithErrorHandling() async {
    try {
      // Note: sensors_plus does not provide a direct availability check.
      // We listen to streams and catch errors.

      print('🔍 Checking sensors...');

      // Try to receive first events from sensors.
      final accelerometerStream = accelerometerEventStream();
      final magnetometerStream = magnetometerEventStream();

      final accelerometerSubscription =
          accelerometerStream.listen((_) {
        print('✅ Accelerometer available');
      }, onError: (e) {
        print('❌ Accelerometer error: $e');
        throw SensorNotAvailableException('Accelerometer');
      });

      final magnetometerSubscription =
          magnetometerStream.listen((_) {
        print('✅ Magnetometer available');
      }, onError: (e) {
        print('❌ Magnetometer error: $e');
        throw SensorNotAvailableException('Magnetometer');
      });

      // Clean up subscriptions.
      await Future.delayed(const Duration(milliseconds: 500));
      await accelerometerSubscription.cancel();
      await magnetometerSubscription.cancel();

      print('✅ Sensors initialized successfully');
      return true;
    } on SensorException {
      rethrow;
    } catch (e, stackTrace) {
      print('❌ Unknown sensor error: $e');
      print(stackTrace);
      throw UnknownException(
        message: 'Failed to initialize sensors.\n\nError: $e',
        originalException: e as Exception?,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get a user-friendly sensor error description.
  static String getSensorErrorDescription(dynamic error) {
    if (error is SensorException) {
      return error.message;
    }
    return 'Sensor error: $error';
  }

  /// Check whether calibration is needed (placeholder).
  static Future<bool> needsMagnetometerCalibration() async {
    // Simplified: a real implementation would require more robust logic.
    return false;
  }

  /// Show calibration guide.
  static Widget getCalibrationGuide(BuildContext context) {
    return AlertDialog(
      title: const Text('Magnetometer calibration'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('To calibrate the magnetometer:'),
          const SizedBox(height: 12),
          _buildStep(1, 'Move your device in a figure-eight'),
          const SizedBox(height: 8),
          _buildStep(2, 'Rotate it in all directions'),
          const SizedBox(height: 8),
          _buildStep(3, 'Wait 10–15 seconds'),
          const SizedBox(height: 16),
          const Text(
            'This helps the magnetometer determine device orientation more accurately.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  static Widget _buildStep(int number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}

/// Network error handler.
class NetworkErrorHandler {
  /// Fetch from an API with error handling.
  static Future<T> fetchWithErrorHandling<T>(
    Future<T> Function() fetch, {
    required String source,
    T Function()? fallback,
  }) async {
    try {
      print('🌐 Loading data from $source...');
      return await fetch();
    } on NetworkException {
      rethrow;
    } catch (e, stackTrace) {
      print('❌ Network error from $source: $e');
      print(stackTrace);

      if (fallback != null) {
        print('⚠️ Using fallback data');
        return fallback();
      }

      throw DataFetchException(source);
    }
  }

  /// Get a user-friendly network error description.
  static String getNetworkErrorDescription(dynamic error) {
    if (error is NetworkException) {
      return error.message;
    }

    if (error.toString().contains('SocketException')) {
      return 'Please check your internet connection.';
    }

    if (error.toString().contains('TimeoutException')) {
      return 'The request timed out. Please try again.';
    }

    return 'Network error: $error';
  }
}

// ============================================================================
// UI HELPER CLASSES FOR ERROR DIALOGS
// ============================================================================

/// Helper utilities for error dialogs/snackbars.
class ErrorDialogHelper {
  /// Show an error dialog.
  static Future<void> showErrorDialog(
    BuildContext context,
    SkyMapException exception, {
    VoidCallback? onAction,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exception.title ?? 'Error'),
        content: Text(exception.message),
        actions: [
          if (exception.action != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onAction?.call();
              },
              child: Text(exception.action!),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
        ],
      ),
    );
  }

  /// Show an error snackbar.
  static void showErrorSnackbar(
    BuildContext context,
    SkyMapException exception, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(exception.message),
        backgroundColor: Colors.red.shade700,
        duration: duration,
        action: SnackBarAction(
          label: 'Close',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show a blocking (critical) error dialog.
  static Future<void> showCriticalErrorDialog(
    BuildContext context,
    SkyMapException exception, {
    VoidCallback? onRetry,
    VoidCallback? onExit,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber, color: Colors.red, size: 40),
        title: Text(exception.title ?? 'Critical error'),
        content: Text(exception.message),
        actions: [
          if (onExit != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onExit();
              },
              child: const Text('Exit'),
            ),
          if (onRetry != null)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: const Text('Try again'),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// LOGGING & ERROR REPORTING
// ============================================================================

/// Logging and (optional) error reporting utilities.
class ErrorLogger {
  /// Log an error.
  static void logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? '[$context]' : '';

    print('❌ $timestamp $contextStr Error: $error');
    if (stackTrace != null) {
      print('Stack trace:\n$stackTrace');
    }

    // TODO: Send to a server for analysis.
    // _sendErrorToServer(error, stackTrace, context);
  }

  /// Log a warning.
  static void logWarning(String message, {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? '[$context]' : '';

    print('⚠️ $timestamp $contextStr Warning: $message');
  }

  /// Log info.
  static void logInfo(String message, {String? context}) {
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? '[$context]' : '';

    print('ℹ️ $timestamp $contextStr Info: $message');
  }

  /// Report an error to a server (placeholder).
  static Future<void> reportError(
    SkyMapException exception, {
    String? userEmail,
    String? userFeedback,
  }) async {
    // TODO: Implement server reporting.
    print('📧 Reporting error...');
    print('Exception: ${exception.message}');
    print('Email: $userEmail');
    print('Feedback: $userFeedback');
  }
}