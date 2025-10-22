import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cryptoimmobilierapp/utils/Routes.dart';
import '../models/UserModel.dart';
import '../api/api_client.dart';
import '../providers/auth_provider.dart';
import '../providers/messaging_provider.dart';
import '../core/messagerie/MessageRoom.dart';
import '../services/socket_service.dart';

class AgentTerrainPage extends StatefulWidget {
  const AgentTerrainPage({Key? key}) : super(key: key);

  @override
  State<AgentTerrainPage> createState() => _AgentTerrainPageState();
}

class _AgentTerrainPageState extends State<AgentTerrainPage> {
  int _selectedIndex = 3; // Set to 3 for "Agent Terrain" tab
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Data fetching states
  bool _isLoading = false;
  String? _errorMessage;
  List<UserModel> _agents = [];

  // Timer for updating elapsed time display
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _fetchAgents();
    _setupSocketListeners();

    // Update UI every 30 seconds to refresh elapsed time (more efficient)
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          // This will rebuild the UI and update all time displays
        });
      }
    });
  }

  void _setupSocketListeners() {
    // Listen for agent status updates
    socketService.onAgentStatusUpdate((data) {
      final agentId = data['agentId'] as String?;
      final availability = data['availability'] as String?;
      final dateAvailableStr = data['dateAvailable'] as String?;

      if (agentId != null && availability != null) {
        setState(() {
          // Find and update the agent in the list
          final index = _agents.indexWhere((agent) => agent.id == agentId);
          if (index != -1) {
            final agent = _agents[index];
            _agents[index] = agent.copyWith(
              availability: availability,
              dateAvailable: dateAvailableStr != null
                  ? DateTime.parse(dateAvailableStr)
                  : null,
            );
          }
        });
      }
    });
  }

  Future<void> _fetchAgents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Session expirée. Veuillez vous reconnecter.';
      });
      return;
    }

    try {
      final response = await apiClient.getAllAgents(token);

      if (response.success && response.data != null) {
        setState(() {
          _agents = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response.message ?? 'Erreur lors du chargement des agents';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<UserModel> get _filteredAgents {
    // First, filter to only show field agents (role = 'field')
    var fieldAgents = _agents.where((agent) => agent.role == 'field').toList();

    // Apply search filter if there's a search query
    if (_searchQuery.isNotEmpty) {
      fieldAgents = fieldAgents
          .where(
            (agent) =>
                agent.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                agent.phone.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Sort: Available agents first, then by longest elapsed time
    fieldAgents.sort((a, b) {
      // 1. Available agents come before unavailable agents
      final aAvailable = a.availability == 'available';
      final bAvailable = b.availability == 'available';

      if (aAvailable && !bAvailable) return -1;
      if (!aAvailable && bAvailable) return 1;

      // 2. Within same availability status, sort by elapsed time
      // Agents with null dateAvailable go to the end
      if (a.dateAvailable == null && b.dateAvailable != null) return 1;
      if (a.dateAvailable != null && b.dateAvailable == null) return -1;
      if (a.dateAvailable == null && b.dateAvailable == null) return 0;

      // 3. Earlier date = more elapsed time = should come first
      return a.dateAvailable!.compareTo(b.dateAvailable!);
    });

    return fieldAgents;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _updateTimer?.cancel();
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

  Future<void> _openDirectMessage(UserModel agent) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );
    final token = authProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session expirée. Veuillez vous reconnecter.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      ),
    );

    try {
      // Validate agent ID
      if (agent.id == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ID de l\'agent invalide'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Find or create direct room with this agent
      final room = await messagingProvider.findOrCreateDirectRoom(
        token: token,
        otherUserId: agent.id!,
      );

      if (!mounted) return;

      // Close loading indicator
      Navigator.pop(context);

      if (room != null) {
        // Navigate to the message room
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MessageRoomPage(room: room)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création de la conversation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Close loading indicator
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatAvailabilityTime(DateTime? dateAvailable, bool isAvailable) {
    if (dateAvailable == null) {
      // Show a default message when no date is available
      return isAvailable ? 'Statut: Disponible' : 'Statut: Indisponible';
    }

    final now = DateTime.now();
    final difference = now.difference(dateAvailable);

    // Calculate hours, minutes, seconds
    final hours = difference.inHours;
    final minutes = difference.inMinutes.remainder(60);
    final seconds = difference.inSeconds.remainder(60);

    // Format as "Xh Xm Xs" (same as reservations)
    return '${hours}h ${minutes}m ${seconds}s';
  }

  Widget _buildAgentCard(UserModel agent) {
    final bool isAvailable = agent.availability == 'available';
    final bool hasPhoto = agent.profilePhoto?.url != null;
    final String availabilityText = _formatAvailabilityTime(
      agent.dateAvailable,
      isAvailable,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAvailable
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with availability status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color:
                  (isAvailable
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      .withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isAvailable ? Icons.check_circle : Icons.cancel,
                  color: isAvailable
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAvailable ? 'Disponible' : 'Indisponible',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isAvailable
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        availabilityText,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              (isAvailable
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444))
                                  .withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile photo
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  backgroundImage: hasPhoto
                      ? NetworkImage(agent.profilePhoto!.url!)
                      : null,
                  child: !hasPhoto
                      ? Icon(
                          Icons.person,
                          size: 32,
                          color: const Color(0xFF6366F1),
                        )
                      : null,
                ),
                const SizedBox(width: 16),

                // Agent info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            agent.phone,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          agent.roleDisplayName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Messagerie button
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => _openDirectMessage(agent),
                        icon: const Icon(
                          Icons.message_outlined,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                        tooltip: 'Envoyer un message',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Messagerie',
                      style: TextStyle(fontSize: 10, color: Color(0xFF6366F1)),
                    ),
                  ],
                ),
              ],
            ),
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
                  Icons.arrow_back,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF6366F1),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text(
                'Voir état des agents',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF6366F1),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                  hintText: 'Rechercher par nom ou téléphone',
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

            // Agent list with loading and error states
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _fetchAgents,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Réessayer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _filteredAgents.isEmpty
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
                            _searchQuery.isEmpty
                                ? 'Aucun agent disponible'
                                : 'Aucun agent trouvé',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchAgents,
                      color: const Color(0xFF6366F1),
                      child: ListView.builder(
                        itemCount: _filteredAgents.length,
                        padding: const EdgeInsets.only(top: 8, bottom: 100),
                        itemBuilder: (context, index) {
                          return _buildAgentCard(_filteredAgents[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
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
      ),
    );
  }
}
