import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cryptoimmobilierapp/utils/Routes.dart';
import 'package:cryptoimmobilierapp/providers/auth_provider.dart';
import 'package:cryptoimmobilierapp/providers/messaging_provider.dart';
import 'package:cryptoimmobilierapp/api/api_client.dart';
import 'package:cryptoimmobilierapp/services/socket_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cryptoimmobilierapp/widgets/notification_bell_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _permissionRequested =
      false; // Track if permission was already requested
  bool _hasActiveReservation = false; // Track if agent has reservation in progress
  bool _isCheckingReservations = false;

  @override
  void initState() {
    super.initState();
    // Reset selected index when page loads
    _selectedIndex = 0;
    // Request permission on first load
    _requestPhonePermission();
    // Check for active reservations
    _checkActiveReservations();
    // Setup socket listeners for reservation updates
    _setupReservationListeners();
  }

  @override
  void dispose() {
    _removeReservationListeners();
    super.dispose();
  }

  void _setupReservationListeners() {
    final socket = socketService.socket;
    
    if (socket != null) {
      // Listen for reservation updates
      socket.on('reservation:updated', (_) {
        if (mounted) _checkActiveReservations();
      });
      
      // Listen for new assignments
      socket.on('reservation:assigned', (_) {
        if (mounted) _checkActiveReservations();
      });
      
      // Listen for state changes (completed, cancelled, in_progress)
      socket.on('reservation:state_changed', (data) {
        debugPrint('📥 Reservation state changed: ${data['newState']}');
        if (mounted) _checkActiveReservations();
      });
    }
  }

  void _removeReservationListeners() {
    final socket = socketService.socket;
    
    if (socket != null) {
      socket.off('reservation:updated');
      socket.off('reservation:assigned');
      socket.off('reservation:state_changed');
    }
  }

  Future<void> _checkActiveReservations() async {
    if (_isCheckingReservations || !mounted) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      var userId = authProvider.currentUser?.id;
      
      // If userId is null, extract from JWT token
      if (userId == null && token != null) {
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final decoded = utf8.decode(base64Url.decode(normalized));
            final Map<String, dynamic> payloadMap = json.decode(decoded);
            userId = payloadMap['userId'] as String?;
          }
        } catch (e) {
          debugPrint('Error extracting userId from token: $e');
        }
      }
      
      if (token == null || userId == null || !authProvider.isField) {
        return;
      }

      setState(() {
        _isCheckingReservations = true;
      });

      final response = await apiClient.getReservations(token);
      
      if (response.success && response.data != null) {
        // Check if agent has any active reservation (pending, assigned, or in_progress)
        final hasActive = response.data!.any((reservation) =>
            reservation.agentTerrainId == userId &&
            (reservation.state == 'pending' || 
             reservation.state == 'assigned' || 
             reservation.state == 'in_progress'));
        
        if (mounted) {
          setState(() {
            _hasActiveReservation = hasActive;
            _isCheckingReservations = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking active reservations: $e');
      if (mounted) {
        setState(() {
          _isCheckingReservations = false;
        });
      }
    }
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
          debugPrint('Permission request error: $e');
        }
      });
    } catch (e) {
      debugPrint('Error in _requestPhonePermission: $e');
    }
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
    
    // Use a flag to track if we should close the dialog
    bool dialogShown = true;
    
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
      debugPrint('🚪 Starting logout process...');
      
      // Get messaging provider
      final messagingProvider = Provider.of<MessagingProvider>(
        context,
        listen: false,
      );

      // Perform logout with messaging cleanup
      await authProvider.logout(messagingProvider: messagingProvider);
      
      debugPrint('✅ Logout completed successfully');

      // Close the loading dialog FIRST
      if (mounted && dialogShown) {
        Navigator.of(context, rootNavigator: false).pop();
        dialogShown = false;
        debugPrint('✅ Loading dialog closed');
      }

      // Small delay to ensure dialog is closed
      await Future.delayed(const Duration(milliseconds: 200));

      // Navigate to welcome screen and clear navigation stack
      if (mounted) {
        debugPrint('🔄 Navigating to welcome screen...');
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.welcome,
          (route) => false,
        );
        debugPrint('✅ Navigation complete');
      }
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      
      // Close loading dialog if still open
      if (mounted && dialogShown) {
        Navigator.of(context, rootNavigator: false).pop();
        dialogShown = false;
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
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AppBar(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.white.withOpacity(0.3),
                elevation: 0,
                leading: IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF6366F1),
                  ),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
                title: Text(
                  'Accueil',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF6366F1),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: const [
                  NotificationBellButton(),
                ],
              ),
            ),
          ),
        ),
        drawer: Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.currentUser;
            final isFieldAgent = authProvider.isField;

            // Debug: Print user data when drawer rebuilds
            debugPrint('HomePage Drawer - User: ${user?.name}');
            debugPrint('HomePage Drawer - Role: ${user?.role}');
            debugPrint('HomePage Drawer - isField: $isFieldAgent');
            debugPrint('HomePage Drawer - isCommercial: ${authProvider.isCommercial}');
            debugPrint('HomePage Drawer - isAdmin: ${authProvider.isAdmin}');
            debugPrint(
              'HomePage Drawer - Profile Photo URL: ${user?.profilePhoto?.url}',
            );
            debugPrint(
              'HomePage Drawer - isAuthenticated: ${authProvider.isAuthenticated}',
            );

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
                    decoration: const BoxDecoration(color: Color(0xFF6366F1)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          backgroundImage: user?.profilePhoto?.url != null
                              ? NetworkImage(user!.profilePhoto!.url!)
                              : null,
                          child: user?.profilePhoto?.url == null
                              ? const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Color(0xFF6366F1),
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
                          if (isFieldAgent)
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
                              subtitle: Text(
                                user?.isAvailable == true
                                    ? 'Disponible'
                                    : 'Indisponible',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: user?.isAvailable == true
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFE11D48),
                                ),
                              ),
                              trailing: Switch(
                                value: user?.isAvailable ?? false,
                                onChanged: _hasActiveReservation ? null : (value) async {
                                  // Update availability via API and Socket.IO
                                  final availability = value
                                      ? 'available'
                                      : 'not_available';

                                  // Show loading indicator
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Mise à jour du statut...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );

                                  // Call the provider method
                                  final success = await authProvider
                                      .updateAvailability(availability);

                                  if (success) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            value
                                                ? 'Vous êtes maintenant disponible'
                                                : 'Vous êtes maintenant indisponible',
                                          ),
                                          backgroundColor: const Color(
                                            0xFF059669,
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            authProvider.errorMessage ??
                                                'Erreur lors de la mise à jour',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                activeColor: const Color(0xFF059669),
                              ),
                            ),

                          if (isFieldAgent) const SizedBox(height: 8),
                          
                          // Suivi (Only for field agents)
                          if (isFieldAgent) ...[
                            Builder(
                              builder: (context) {
                                debugPrint('🔵 SUIVI MENU ITEM IS BEING RENDERED');
                                return const SizedBox.shrink();
                              },
                            ),
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              leading: const Icon(
                                Icons.assignment_outlined,
                                color: Color(0xFF6366F1),
                              ),
                              title: const Text(
                                'Suivi',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Mes rendez-vous assignés',
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

                          // Change Language (Disabled)
                          Opacity(
                            opacity: 0.5,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              leading: const Icon(Icons.language),
                              title: const Text(
                                'Changer la langue',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: const Text(
                                'Français (Bientôt)',
                                style: TextStyle(fontSize: 13),
                              ),
                              enabled: false,
                            ),
                          ),

                          const SizedBox(height: 8),
                          const Divider(height: 1, indent: 20, endIndent: 20),
                          const SizedBox(height: 8),

                          // Dark Mode (Disabled)
                          Opacity(
                            opacity: 0.5,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 4,
                              ),
                              leading: const Icon(Icons.dark_mode_outlined),
                              title: const Text(
                                'Mode sombre',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Switch(value: false, onChanged: null),
                              enabled: false,
                            ),
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
                            leading: const Icon(
                              Icons.account_circle_outlined,
                              color: Color(0xFF6366F1),
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
                      title: 'Réserver un\nrendez-vous',
                      subtitle: 'Prenez un rendez-vous\npour un client',
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
                      title: 'Voir les\nrendez-vous',
                      subtitle: 'Voir les rendez-vous de\nvos clients',
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
                    ),
                    _buildCard(
                      title: 'Statistiques',
                      subtitle: 'Voir vos statistiques\net performances',
                      color: const Color(0xFF6366F1),
                      icon: Icons.analytics_outlined,
                      textColor: Colors.white,
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
              padding: const EdgeInsets.only(
                left: 7.0,
                right: 7.0,
                bottom: 16.0,
              ),
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
                        selectedItemColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : const Color(0xFF6366F1),
                        unselectedItemColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.white60
                                : const Color(0xFF6366F1).withOpacity(0.5),
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
