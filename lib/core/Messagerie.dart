import 'package:flutter/material.dart';
import 'package:cryptoimmobilierapp/utils/Routes.dart';

class MessageriePage extends StatefulWidget {
  const MessageriePage({Key? key}) : super(key: key);

  @override
  State<MessageriePage> createState() => _MessageriePageState();
}

class _MessageriePageState extends State<MessageriePage> {
  int _selectedIndex = 1; // Set to 1 for "Messagerie" tab

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // Already on this page

    switch (index) {
      case 0:
        // Navigate to Home
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
        break;
      case 1:
        // Already on Messagerie
        setState(() {
          _selectedIndex = 1;
        });
        break;
      case 2:
        // Navigate to Gestion des appels
        Navigator.pushReplacementNamed(context, AppRoutes.gestionAppels);
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
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: AppBar(
            backgroundColor: const Color(0xFF6366F1),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: const Text(
              'Messagerie',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Messagerie',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'À venir...',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade300),
                ),
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
}
