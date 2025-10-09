import 'package:flutter/material.dart';
import 'package:cryptoimmobilierapp/utils/Routes.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Reset selected index when page loads
    _selectedIndex = 0;
    // Request permission on first load
    _requestPhonePermission();
  }

  Future<void> _requestPhonePermission() async {
    // Wait for the first frame to be rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final phoneStatus = await Permission.phone.status;
      if (phoneStatus.isDenied) {
        await Permission.phone.request();
      }
    });
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
        drawer: Drawer(
          child: Container(
            color: Colors.white,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF6366F1)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 35,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Menu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Drawer content will be added later
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Content à venir...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
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
