import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext context, FlutterErrorDetails error)? errorBuilder;
  final void Function(FlutterErrorDetails error)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();

    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      setState(() {
        _errorDetails = details;
      });
      widget.onError?.call(details);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(context, _errorDetails!);
      }

      return _buildDefaultErrorWidget(context, _errorDetails!);
    }

    return widget.child;
  }

  Widget _buildDefaultErrorWidget(BuildContext context, FlutterErrorDetails error) {
    return Material(
      child: Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We apologize for the inconvenience. Please try refreshing the page.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _errorDetails = null;
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // Report error (could integrate with error reporting service)
                _reportError(error);
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Report Issue'),
            ),
          ],
        ),
      ),
    );
  }

  void _reportError(FlutterErrorDetails error) {
    // Implement error reporting logic here
    // Could send to services like Sentry, Firebase Crashlytics, etc.
    print('Error reported: ${error.exception}');
    print('Stack trace: ${error.stack}');
  }
}

/// Error boundary for specific widgets
class WidgetErrorBoundary extends StatelessWidget {
  final Widget child;
  final Widget Function(BuildContext context, dynamic error, StackTrace? stackTrace)? errorBuilder;

  const WidgetErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          if (errorBuilder != null) {
            return errorBuilder!(context, error, stackTrace);
          }

          return _buildDefaultErrorWidget(context, error);
        }
      },
    );
  }

  Widget _buildDefaultErrorWidget(BuildContext context, dynamic error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            'Widget Error',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Async error boundary for Future operations
class AsyncErrorBoundary extends StatelessWidget {
  final Future<void> Function() operation;
  final Widget Function(BuildContext context) loadingBuilder;
  final Widget Function(BuildContext context, dynamic error) errorBuilder;
  final Widget Function(BuildContext context) successBuilder;

  const AsyncErrorBoundary({
    super.key,
    required this.operation,
    required this.loadingBuilder,
    required this.errorBuilder,
    required this.successBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: operation(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder(context);
        }

        if (snapshot.hasError) {
          return errorBuilder(context, snapshot.error);
        }

        return successBuilder(context);
      },
    );
  }
}

/// Stream error boundary
class StreamErrorBoundary<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context) loadingBuilder;
  final Widget Function(BuildContext context, dynamic error) errorBuilder;
  final Widget Function(BuildContext context, T data) successBuilder;

  const StreamErrorBoundary({
    super.key,
    required this.stream,
    required this.loadingBuilder,
    required this.errorBuilder,
    required this.successBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingBuilder(context);
        }

        if (snapshot.hasError) {
          return errorBuilder(context, snapshot.error);
        }

        if (snapshot.hasData) {
          return successBuilder(context, snapshot.data as T);
        }

        return loadingBuilder(context);
      },
    );
  }
}

