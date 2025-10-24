import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/web_error_handler.dart';

class RouteGuard extends GetMiddleware {
  final GetStorage _storage = GetStorage();

  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    print('>>> ============================================');
    print('>>> ROUTE GUARD: Intercepting navigation');
    print('>>> Target route: $route');
    print('>>> ============================================');

    // Allow public routes (login, signup, splash)
    if (route == Routes.login || 
        route == Routes.signup || 
        route == Routes.splash) {
      print('>>> Public route - allowing access');
      return null;
    }

    // Check if user is logged in
    final userId = _storage.read('userId');
    final sessionId = _storage.read('sessionId');
    final role = _storage.read('role');

    print('>>> Session Check:');
    print('>>> - User ID: ${userId ?? "NOT FOUND"}');
    print('>>> - Session ID: ${sessionId != null ? "EXISTS" : "NOT FOUND"}');
    print('>>> - Role: ${role ?? "NOT FOUND"}');

    // If no session, redirect to login
    if (userId == null || sessionId == null || role == null) {
      print('>>> âœ— No valid session - redirecting to login');
      print('>>> ============================================');
      
      // Clear any invalid session data
      _storage.erase();
      
      return const RouteSettings(name: Routes.login);
    }

    // Validate role-based access
    final hasAccess = _validateRoleAccess(route, role);

    if (!hasAccess) {
      print('>>> âœ— Unauthorized access attempt!');
      print('>>> User role: $role');
      print('>>> Target route: $route');
      print('>>> ============================================');
      
      // Log security violation
      _logSecurityViolation(userId, role, route);
      
      // Redirect to appropriate home based on role
      return RouteSettings(name: _getHomeRouteForRole(role));
    }

    print('>>> âœ" Access granted');
    print('>>> ============================================');
    return null;
  }

  /// Validate if user's role can access the route
  bool _validateRoleAccess(String? route, String role) {
    // Define role-based access rules
    final Map<String, List<String>> routeAccessMap = {
      Routes.userHome: ['user', 'customer'],
      Routes.adminHome: ['admin', 'staff'],
      Routes.superAdminHome: ['developer'],
      Routes.createStaff: ['admin'],
      Routes.staffHome: ['staff'],
    };

    // Check if route has access restrictions
    if (!routeAccessMap.containsKey(route)) {
      // If route not in map, allow access (or you can deny by default)
      return true;
    }

    // Check if user's role is in allowed roles for this route
    final allowedRoles = routeAccessMap[route]!;
    return allowedRoles.contains(role);
  }

  /// Get home route based on user role
  String _getHomeRouteForRole(String role) {
    switch (role) {
      case 'admin':
      case 'staff':
        return Routes.adminHome;
      case 'developer':
        return Routes.superAdminHome;
      case 'user':
      case 'customer':
      default:
        return Routes.userHome;
    }
  }

  /// Log security violation attempts
  void _logSecurityViolation(String userId, String role, String? targetRoute) {
    final timestamp = DateTime.now().toIso8601String();
    
    print('>>> ============================================');
    print('>>> ðŸšØ SECURITY VIOLATION DETECTED ðŸšØ');
    print('>>> Timestamp: $timestamp');
    print('>>> User ID: $userId');
    print('>>> User Role: $role');
    print('>>> Attempted Route: $targetRoute');
    print('>>> ============================================');

    // Store violation in local storage for admin review
    final violations = _storage.read<List>('security_violations') ?? [];
    violations.add({
      'timestamp': timestamp,
      'userId': userId,
      'role': role,
      'attemptedRoute': targetRoute,
    });
    
    // Keep only last 100 violations
    if (violations.length > 100) {
      violations.removeAt(0);
    }
    
    _storage.write('security_violations', violations);

    // Show warning to user
    Future.delayed(const Duration(milliseconds: 500), () {
      WebErrorHandler.handleError(
        'Unauthorized Access',
        context: 'You do not have permission to access this page',
      );
    });
  }
}