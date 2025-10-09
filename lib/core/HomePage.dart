import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cryptoimmobilierapp/utils/Routes.dart';
import 'package:cryptoimmobilierapp/providers/auth_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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

  @override
  void initState() {
    super.initState();
    // Reset selected index when page loads
    _selectedIndex = 0;
    // Request permission on first load
    _requestPhonePermission();
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

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );

    try {
      // Perform logout
      await authProvider.logout();

      // Wait a tiny bit to ensure logout is complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate to login screen
      if (!mounted) return;

      // Close the loading dialog first
      Navigator.of(context).pop();

      // Then navigate to login and clear stack
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (e) {
      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la déconnexion: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('lib/assets/CryptoBackground.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: AppBar(
            backgroundColor: const Color(0xFF6366F1),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            title: const Text(
              'Accueil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
                onPressed: () {
                  // Notification action
                },
              ),
            ],
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
                    decoration: const BoxDecoration(color: Color(0xFF6366F1)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF6366F1),
                          ),
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
                          const SizedBox(height: 8),

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
                                onChanged: (value) {
                                  // TODO: Update availability via API
                                  // For now, just update locally
                                  if (user != null) {
                                    authProvider.updateUser(
                                      user.copyWith(
                                        availability: value
                                            ? 'available'
                                            : 'not_available',
                                      ),
                                    );
                                  }
                                },
                                activeColor: const Color(0xFF059669),
                              ),
                            ),

                          if (isFieldAgent)
                            const Divider(height: 1, indent: 20, endIndent: 20),

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

                          const Divider(height: 1, indent: 20, endIndent: 20),

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

                          const Divider(height: 1, indent: 20, endIndent: 20),

                          // Profile Settings
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 4,
                            ),
                            leading: const Icon(
                              Icons.settings_outlined,
                              color: Color(0xFF6366F1),
                            ),
                            title: const Text(
                              'Paramètres du profil',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(
                                context,
                                AppRoutes.profileSettings,
                              );
                            },
                          ),

                          const Divider(height: 1, indent: 20, endIndent: 20),
                          const SizedBox(height: 16),

                          // Logout Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _handleLogout(authProvider),
                                icon: const Icon(Icons.logout, size: 20),
                                label: const Text('Déconnexion'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
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
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(left: 7.0, right: 7.0, bottom: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                backgroundColor: const Color(0xFF6366F1),
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white70,
                selectedFontSize: 10,
                unselectedFontSize: 9,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                elevation: 0,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Accueil',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.chat_outlined),
                    activeIcon: Icon(Icons.chat),
                    label: 'Messagerie',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.support_agent_outlined),
                    activeIcon: Icon(Icons.support_agent),
                    label: 'Gestion des appels',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.people_outline),
                    activeIcon: Icon(Icons.people),
                    label: 'Agents Terrain',
                  ),
                ],
              ),
            ),
          ),
        ),
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
