import 'package:flutter/material.dart';

class PermissionGuard extends StatelessWidget {
  final bool hasPermission;
  final String requiredPermission;
  final Widget child;
  final bool showOverlay;

  const PermissionGuard({
    super.key,
    required this.hasPermission,
    required this.requiredPermission,
    required this.child,
    this.showOverlay = true,
  });

  static const Color primaryTeal = Color(0xFF5B9BD5);
  static const Color vetOrange = Color(0xFFF59E0B);
  static const Color mediumGray = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    if (hasPermission) {
      return child;
    }

    if (!showOverlay) {
      return _buildRestrictedMessage(context);
    }

    return Stack(
      children: [
        // Blurred content
        IgnorePointer(
          child: Opacity(
            opacity: 0.3,
            child: child,
          ),
        ),
        // Overlay
        _buildRestrictedOverlay(context),
      ],
    );
  }

  Widget _buildRestrictedMessage(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: vetOrange.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 64,
              color: vetOrange,
            ),
            const SizedBox(height: 16),
            Text(
              'Access Restricted',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need "$requiredPermission" permission to access this page.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please contact your clinic administrator for access.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestrictedOverlay(BuildContext context) {
    return Container(
      color: Colors.white.withOpacity(0.95),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: vetOrange.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: vetOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: vetOrange,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Access Restricted',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: vetOrange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: vetOrange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security, color: vetOrange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Required: $requiredPermission',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'You do not have permission to access this page. '
                'Your account needs "$requiredPermission" authorization.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryTeal.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: primaryTeal, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Contact your clinic administrator to request access.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner to show at top of pages when user has limited access
class PermissionBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? color;

  const PermissionBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
    this.color,
  });

  static const Color vetOrange = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final bannerColor = color ?? vetOrange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: bannerColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: bannerColor.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
