import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class PosSidebar extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onLogout;
  final String userName;
  final String userInitial;
  final String? storeLogo;
  final String storeName;

  const PosSidebar({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onLogout,
    required this.userName,
    required this.userInitial,
    this.storeLogo,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    final nameParts = storeName.split(' ');
    final firstLine = nameParts.isNotEmpty
        ? nameParts[0].toUpperCase()
        : storeName.toUpperCase();
    final secondLine = nameParts.length > 1
        ? nameParts.sublist(1).join(' ').toUpperCase()
        : '';

    return Stack(
      children: [
        if (isOpen)
          GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: isOpen ? 0 : -280,
          top: 0,
          bottom: 0,
          width: 280,
          child: Material(
            elevation: 16,
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[100]!),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                firstLine,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF5a6c37),
                                  height: 1.1,
                                ),
                              ),
                              if (secondLine.isNotEmpty)
                                Text(
                                  secondLine,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF5a6c37),
                                    height: 1.1,
                                  ),
                                ),
                              Text(
                                'Point of Sale',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.5,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),

                          // Close Button
                          IconButton(
                            onPressed: onClose,
                            icon: Icon(
                              LucideIcons.x,
                              color: Colors.grey[500],
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Navigation Links
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final String currentPath = GoRouterState.of(
                            context,
                          ).uri.path;

                          // Helper to check active state
                          bool isPathActive(String path) {
                            return currentPath == path;
                          }

                          return ListView(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 12,
                            ),
                            children: [
                              _buildNavItem(
                                context,
                                icon: LucideIcons.layoutGrid,
                                label: 'Dashboard',
                                path: '/dashboard',
                                isActive: isPathActive('/dashboard'),
                              ),
                              _buildNavItem(
                                context,
                                icon: LucideIcons.monitor,
                                label: 'Cashier',
                                path: '/',
                                isActive: isPathActive('/'),
                              ),
                              _buildNavItem(
                                context,
                                icon: LucideIcons.tag,
                                label: 'Menu',
                                path: '/menu',
                                isActive: isPathActive('/menu'),
                              ),
                              _buildNavItem(
                                context,
                                icon: LucideIcons.clock,
                                label: 'Transaction History',
                                path: '/history',
                                isActive: isPathActive('/history'),
                              ),
                              _buildNavItem(
                                context,
                                icon: LucideIcons.users,
                                label: 'Members',
                                path: '/members',
                                isActive: isPathActive('/members'),
                              ),
                              _buildNavItem(
                                context,
                                icon: LucideIcons.package,
                                label: 'Inventory',
                                path: '/inventory',
                                isActive: isPathActive('/inventory'),
                              ),
                              _buildNavItem(
                                context,
                                icon: LucideIcons.calendar,
                                label: 'Shift History',
                                path: '/shifts',
                                isActive: isPathActive('/shifts'),
                              ),
                              _buildNavItem(
                                context,
                                icon: LucideIcons.settings,
                                label: 'Settings',
                                path: '/settings',
                                isActive: isPathActive('/settings'),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                    // Footer: User Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[100]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          // User Avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF5a6c37,
                              ).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                userInitial,
                                style: const TextStyle(
                                  color: Color(0xFF5a6c37),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // User Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[500],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Logout Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: onLogout,
                              icon: Icon(
                                LucideIcons.logOut,
                                color: Colors.red[500],
                                size: 20,
                              ),
                              tooltip: 'Sign Out',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String path,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isActive ? const Color(0xFF5a6c37) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            onClose();
            if (!isActive) {
              context.go(path);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive ? Colors.white : Colors.grey[400],
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
