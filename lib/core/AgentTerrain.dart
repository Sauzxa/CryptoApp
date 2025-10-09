import 'package:flutter/material.dart';
import 'package:cryptoimmobilierapp/utils/Routes.dart';

class AgentTerrainPage extends StatefulWidget {
  const AgentTerrainPage({Key? key}) : super(key: key);

  @override
  State<AgentTerrainPage> createState() => _AgentTerrainPageState();
}

class _AgentTerrainPageState extends State<AgentTerrainPage> {
  int _selectedIndex = 3; // Set to 3 for "Agent Terrain" tab
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Sample agent data - replace with actual data source later
  final List<Map<String, dynamic>> _agents = [
    {
      'name': 'Fergune AbdElraouf',
      'available': true,
      'hasImage': true,
      'elapsedTime': '2h 30min',
    },
    {
      'name': 'Benzaoui khaled',
      'available': false,
      'hasImage': false,
      'elapsedTime': '45min',
    },
    {
      'name': 'Zergat Mouhamed',
      'available': false,
      'hasImage': true,
      'elapsedTime': '1h 15min',
    },
    {
      'name': 'Labandji Omar',
      'available': true,
      'hasImage': false,
      'elapsedTime': '30min',
    },
    {
      'name': 'Derriche sami',
      'available': true,
      'hasImage': false,
      'elapsedTime': '3h 20min',
    },
    {
      'name': 'Khider wasim',
      'available': true,
      'hasImage': false,
      'elapsedTime': '1h 05min',
    },
    {
      'name': 'ziddene khaled',
      'available': false,
      'hasImage': false,
      'elapsedTime': '50min',
    },
  ];

  List<Map<String, dynamic>> get _filteredAgents {
    if (_searchQuery.isEmpty) {
      return _agents;
    }
    return _agents
        .where(
          (agent) =>
              agent['name'].toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.messagerie);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.gestionAppels);
        break;
      case 3:
        setState(() {
          _selectedIndex = 3;
        });
        break;
    }
  }

  Widget _buildAgentCard(Map<String, dynamic> agent) {
    final bool isAvailable = agent['available'] as bool;
    final bool hasImage = agent['hasImage'] as bool;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile image or icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: hasImage
                  ? Colors.grey.shade200
                  : const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: hasImage
                ? ClipOval(
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey.shade600,
                    ),
                  )
                : Icon(
                    Icons.person_outline,
                    size: 30,
                    color: const Color(0xFF6366F1),
                  ),
          ),
          const SizedBox(width: 16),
          // Agent name
          Expanded(
            child: Text(
              agent['name'],
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          // Status badge and elapsed time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFECDD3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isAvailable ? 'Disponible' : 'Indisponible',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAvailable
                        ? const Color(0xFF059669)
                        : const Color(0xFFE11D48),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                agent['elapsedTime'],
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
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
            'Voir état des agents',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Entrez le nom de l\'agent',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            // Agent list
            Expanded(
              child: _filteredAgents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun agent trouvé',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredAgents.length,
                      padding: const EdgeInsets.only(bottom: 100),
                      itemBuilder: (context, index) {
                        return _buildAgentCard(_filteredAgents[index]);
                      },
                    ),
            ),
          ],
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
    );
  }
}
