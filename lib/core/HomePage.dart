import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:CryptoApp/utils/Routes.dart';
import 'package:CryptoApp/providers/auth_provider.dart';
import 'package:CryptoApp/providers/messaging_provider.dart';
import 'package:CryptoApp/providers/theme_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:CryptoApp/widgets/notification_bell_button.dart';
import '../utils/colors.dart';
import '../services/socket_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _permissionRequested =
      false; // Track if permission was already requested

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Reset selected index when page loads
    _selectedIndex = 0;
    // Request permission on first load
    _requestPhonePermission();
    // Setup socket listeners for availability updates
    _setupSocketListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _removeSocketListeners();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app comes to foreground, check availability again
    if (state == AppLifecycleState.resumed) {}
  }

  void _setupSocketListeners() {
    // Listen for reservation assigned event - show notification only
    // NOTE: availability update is handled by agent:status_changed in AuthProvider
    socketService.onReservationAssigned((data) {
      debugPrint('📥 HomePage: Reservation assigned: $data');

      if (!mounted) return;

      // Show notification about new assignment
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nouvelle visite assignée - Vous êtes maintenant indisponible',
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
        ),
      );
    });

    // Listen for availability toggle enabled event from backend
    // This is triggered when agent submits rapport and becomes available again
    socketService.onAvailabilityToggleEnabled((data) {
      debugPrint('📥 HomePage: Availability toggle enabled: $data');

      if (!mounted) return;

      // Refresh user data from AuthProvider to get updated availability
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.refreshUser().then((success) {
        if (success) {
          debugPrint('✅ HomePage: User data refreshed, availability updated');

          // Show snackbar notification
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  data['message'] ?? 'Vous êtes maintenant disponible',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      });
    });
  }

  void _removeSocketListeners() {
    // Socket listeners are automatically removed when socket disconnects
    // This is just a placeholder for future cleanup if needed
    debugPrint('🧹 HomePage: Cleaning up socket listeners');
  }

  Future<void> _requestPhonePermission() async {
    // Prevent duplicate requests
    if (_permissionRequested) return;

    _permissionRequested = true;

    try {
      // Wait for the first frame to be rendered
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        try {
          final phoneStatus = await Permission.phone.status;

          // Only request if denied and not permanently denied
          if (phoneStatus.isDenied) {
            await Permission.phone.request();
          } else if (phoneStatus.isPermanentlyDenied) {
            // Show dialog to open app settings if permanently denied
            if (!mounted) return;
            _showPermissionSettingsDialog();
          }
        } catch (e) {
          // Handle any permission-related errors silently
        }
      });
    } catch (e) {}
  }

  void _showPermissionSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission téléphone requise'),
        content: const Text(
          'L\'accès au téléphone est nécessaire pour certaines fonctionnalités. '
          'Veuillez activer la permission dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Paramètres'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(AuthProvider authProvider) async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    // If user confirmed logout
    if (shouldLogout != true) return;

    // Show loading dialog and get the context
    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );

    try {
      // Get messaging provider
      final messagingProvider = Provider.of<MessagingProvider>(
        context,
        listen: false,
      );

      print('📍 Starting logout process...');

      // Perform logout with messaging cleanup with timeout
      await authProvider
          .logout(messagingProvider: messagingProvider)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⚠️ Logout timed out, but continuing with navigation');
            },
          );

      print('✅ Logout completed');

      // Close the loading dialog using root navigator
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        print('✅ Loading dialog closed');
      }

      // Small delay to ensure dialog is fully closed
      await Future.delayed(const Duration(milliseconds: 300));

      // Navigate to welcome screen and clear navigation stack
      if (mounted) {
        print('📍 Navigating to welcome screen...');
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
        print('✅ Navigation completed');
      }
    } catch (e) {
      print('❌ Logout error: $e');

      // Close loading dialog if still open
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
          print('✅ Dialog closed after error');
        } catch (navError) {
          print('⚠️ Could not pop dialog: $navError');
          // If pop fails, try to navigate anyway
          if (mounted) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.welcome, (route) => false);
          }
        }
      }

      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    // If already on home and tapping home, do nothing
    if (index == 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return;
    }

    // Check if field agent is trying to access Agent Terrain
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (index == 3 && authProvider.isField) {
      // Show access denied message for field agents
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.lock, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Accès refusé - Cette fonctionnalité n\'est pas disponible',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    // Navigate based on selected index
    switch (index) {
      case 1:
        // Navigate to Messagerie page
        Navigator.pushNamed(context, AppRoutes.messagerie).then((_) {
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
      case 2:
        // Navigate to Gestion des appels page
        Navigator.pushNamed(context, AppRoutes.gestionAppels).then((_) {
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
      case 3:
        // Navigate to Agent Terrain page
        Navigator.pushNamed(context, AppRoutes.agentTerrain).then((_) {
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.glassEffectDark
                  : AppColors.glassEffectLight,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.menu,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
              title: Text(
                'Accueil',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              actions: const [NotificationBellButton()],
            ),
          ),
        ),
      ),
      drawer: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          final isFieldAgent = authProvider.isField;

          return Drawer(
            child: Column(
              children: [
                // Drawer Header with profile
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 20,
                    bottom: 20,
                    left: 20,
                    right: 20,
                  ),
                  decoration: BoxDecoration(color: AppColors.statisticsPurple),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        backgroundImage: (user?.profilePhoto?.url != null)
                            ? NetworkImage(user!.profilePhoto!.url!)
                            : null,
                        child: user?.profilePhoto?.url == null
                            ? Icon(
                                Icons.person,
                                size: 40,
                                color: AppColors.statisticsPurple,
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        user?.name ?? 'Utilisateur',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.roleDisplayName ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // Change State (Only for field agents)
                        if (isFieldAgent) ...[
                          Builder(
                            builder: (context) {
                              return const SizedBox.shrink();
                            },
                          ),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            title: const Text(
                              'Changer l\'état',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Selector<AuthProvider, String?>(
                              selector: (context, auth) =>
                                  auth.currentUser?.availability ??
                                  'not_available',
                              builder: (context, availability, child) => Text(
                                availability == 'available'
                                    ? 'Disponible'
                                    : 'Indisponible',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: availability == 'available'
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFE11D48),
                                ),
                              ),
                            ),
                            trailing: Consumer<AuthProvider>(
                              builder: (context, auth, child) => Switch(
                                value:
                                    auth.currentUser?.availability ==
                                    'available',
                                onChanged: (value) async {
                                  final newAvailability = value
                                      ? 'available'
                                      : 'not_available';

                                  // Capture messenger BEFORE async gap
                                  final messenger = ScaffoldMessenger.of(
                                    context,
                                  );

                                  final success = await auth.updateAvailability(
                                    newAvailability,
                                  );

                                  if (!success && mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          auth.errorMessage ??
                                              'Impossible de changer la disponibilité',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 4),
                                      ),
                                    );
                                  }
                                },
                                activeColor: const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],

                        if (isFieldAgent) const SizedBox(height: 8),

                        // Suivi (Only for field agents)
                        if (isFieldAgent) ...[
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            leading: Icon(
                              Icons.assignment_outlined,
                              color: AppColors.statisticsPurple,
                            ),
                            title: const Text(
                              'Suivre mes visites',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Mes Visites assignés',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () {
                              Navigator.pop(context); // Close drawer
                              Navigator.pushNamed(context, AppRoutes.suivi);
                            },
                          ),
                        ],

                        if (isFieldAgent) const SizedBox(height: 8),
                        if (isFieldAgent)
                          const Divider(height: 1, indent: 20, endIndent: 20),
                        if (isFieldAgent) const SizedBox(height: 8),

                        // Suivi Commercial (Only for commercial users)
                        if (authProvider.isCommercial) ...[
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            leading: Icon(
                              Icons.assignment_outlined,
                              color: AppColors.statisticsPurple,
                            ),
                            title: const Text(
                              'Suivi',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Suivi des rendez-vous',
                              style: TextStyle(fontSize: 13),
                            ),
                            onTap: () {
                              Navigator.pop(context); // Close drawer
                              Navigator.pushNamed(
                                context,
                                AppRoutes.commercialSuivi,
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          const SizedBox(height: 8),
                        ],

                        // Dark Mode Toggle
                        Consumer<ThemeProvider>(
                          builder: (context, themeProvider, child) {
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              leading: Icon(
                                themeProvider.isDarkMode
                                    ? Icons.dark_mode
                                    : Icons.light_mode,
                                color: AppColors.statisticsPurple,
                              ),
                              title: Text(
                                'Mode sombre',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.color,
                                ),
                              ),
                              subtitle: Text(
                                themeProvider.isDarkMode
                                    ? 'Actuellement en mode sombre'
                                    : 'Actuellement en mode clair',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                              ),
                              trailing: Switch(
                                value: themeProvider.isDarkMode,
                                onChanged: (value) =>
                                    themeProvider.toggleTheme(),
                                activeColor: AppColors.statisticsPurple,
                                activeTrackColor: AppColors.statisticsPurple
                                    .withOpacity(0.3),
                                inactiveThumbColor: Colors.grey[300],
                                inactiveTrackColor: Colors.grey[200],
                              ),
                              onTap: () => themeProvider.toggleTheme(),
                            );
                          },
                        ),

                        const SizedBox(height: 8),
                        const Divider(height: 1, indent: 20, endIndent: 20),
                        const SizedBox(height: 8),

                        // Profile Settings
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          leading: Icon(
                            Icons.account_circle_outlined,
                            color: AppColors.statisticsPurple,
                          ),
                          title: const Text(
                            'Paramètres du profil',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              AppRoutes.profileSettings,
                            );
                          },
                        ),

                        const SizedBox(height: 8),
                        const Divider(height: 1, indent: 20, endIndent: 20),
                        const SizedBox(height: 20),

                        // Logout Button
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _handleLogout(authProvider),
                              icon: const Icon(Icons.logout, size: 20),
                              label: const Text('Déconnexion'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              // Grid of cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  _buildCard(
                    title: 'Réserver un\nrendez-vous ou Visite',
                    subtitle: 'Prenez rendez-vous\n ou Visite pour un client',
                    color: const Color(0xFF93C5FD),
                    icon: Icons.edit_calendar_outlined,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.reserverRendezVous,
                      );
                    },
                  ),
                  _buildCard(
                    title: 'Voir les\nvisites',
                    subtitle: 'Voir les visites de\nvos clients',
                    color: const Color(0xFF7DD3FC),
                    icon: Icons.content_paste_outlined,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.reservations);
                    },
                  ),
                  _buildCard(
                    title: 'Voir\ndocuments',
                    subtitle:
                        'Voir les documents pour\nles traitements des\nréservations',
                    color: const Color(0xFF475569),
                    icon: Icons.article_outlined,
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.documents);
                    },
                  ),
                ],
              ),
              const SizedBox(
                height: 100,
              ), // Extra space for floating navigation
            ],
          ),
        ),
      ),
      bottomNavigationBar: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final isFieldAgent = authProvider.isField;

          return Padding(
            padding: const EdgeInsets.only(left: 7.0, right: 7.0, bottom: 16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? [
                                Colors.black.withOpacity(0.4),
                                Colors.black.withOpacity(0.3),
                              ]
                            : [
                                Colors.white.withOpacity(0.4),
                                Colors.white.withOpacity(0.3),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withOpacity(0.2)
                            : Colors.white.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: BottomNavigationBar(
                      type: BottomNavigationBarType.fixed,
                      backgroundColor: Colors.transparent,
                      selectedItemColor: AppColors.primaryPurple,
                      unselectedItemColor: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color,
                      selectedFontSize: 10,
                      unselectedFontSize: 9,
                      currentIndex: _selectedIndex,
                      onTap: _onItemTapped,
                      elevation: 0,
                      items: [
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.home_outlined),
                          activeIcon: Icon(Icons.home),
                          label: 'Accueil',
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.chat_outlined),
                          activeIcon: Icon(Icons.chat),
                          label: 'Messagerie',
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(Icons.support_agent_outlined),
                          activeIcon: Icon(Icons.support_agent),
                          label: 'Gestion des appels',
                        ),
                        BottomNavigationBarItem(
                          icon: Opacity(
                            opacity: isFieldAgent ? 0.3 : 1.0,
                            child: const Icon(Icons.people_outline),
                          ),
                          activeIcon: Opacity(
                            opacity: isFieldAgent ? 0.3 : 1.0,
                            child: const Icon(Icons.people),
                          ),
                          label: 'Agents Terrain',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    Color textColor = const Color(0xFF1E293B),
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: textColor, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
