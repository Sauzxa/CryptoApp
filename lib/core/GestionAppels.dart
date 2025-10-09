import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cryptoimmobilierapp/utils/Routes.dart';

class GestionAppelsPage extends StatefulWidget {
  const GestionAppelsPage({Key? key}) : super(key: key);

  @override
  State<GestionAppelsPage> createState() => _GestionAppelsPageState();
}

class _GestionAppelsPageState extends State<GestionAppelsPage> {
  int _selectedIndex = 2; // Set to 2 for "Gestion des appels" tab
  List<CallLogEntry> _callLogs = [];
  List<CallLogEntry> _filteredCallLogs = [];
  bool _isLoading = false;
  bool _hasPermission = false;
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'incoming', 'outgoing'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionAndLoadLogs() async {
    try {
      print('GestionAppels: Checking permission...');
      final phoneStatus = await Permission.phone.status;
      print('GestionAppels: Permission status: $phoneStatus');

      setState(() {
        _hasPermission = phoneStatus.isGranted;
      });

      if (phoneStatus.isGranted) {
        print('GestionAppels: Permission granted, loading call logs...');
        await _loadCallLogs();
      } else if (phoneStatus.isDenied) {
        print('GestionAppels: Permission denied, requesting...');
        await _requestPermission();
        if (_hasPermission) {
          await _loadCallLogs();
        }
      } else if (phoneStatus.isPermanentlyDenied) {
        print('GestionAppels: Permission permanently denied');
        _showPermissionDialog();
      }
    } catch (e, stackTrace) {
      print('GestionAppels: Error in checkPermissionAndLoadLogs: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _hasPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    try {
      var phoneStatus = await Permission.phone.status;

      if (phoneStatus.isDenied) {
        phoneStatus = await Permission.phone.request();
      }

      if (phoneStatus.isPermanentlyDenied) {
        setState(() {
          _hasPermission = false;
        });
        _showPermissionDialog();
        return;
      }

      setState(() {
        _hasPermission = phoneStatus.isGranted;
      });
    } catch (e) {
      // Handle permission request errors (e.g., already requesting)
      debugPrint('GestionAppels: Error requesting permission: $e');
      setState(() {
        _hasPermission = false;
      });
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission requise'),
        content: const Text(
          'Cette application a besoin d\'accéder aux journaux téléphoniques pour afficher l\'historique des appels. '
          'Veuillez accorder l\'autorisation dans les paramètres de l\'application.',
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
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCallLogs() async {
    if (!_hasPermission) {
      print('GestionAppels: No permission to load call logs');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('GestionAppels: Fetching call logs...');
      // Limit to last 100 call logs for better performance
      final Iterable<CallLogEntry> logs = await CallLog.query(
        dateFrom: DateTime.now()
            .subtract(const Duration(days: 30))
            .millisecondsSinceEpoch,
        dateTo: DateTime.now().millisecondsSinceEpoch,
      );

      // Take only the first 100 entries
      final limitedLogs = logs.take(100).toList();
      print('GestionAppels: Fetched ${limitedLogs.length} call logs');

      setState(() {
        _callLogs = limitedLogs;
        _filteredCallLogs = limitedLogs;
        _isLoading = false;
      });
      _applyFilters();
      print('GestionAppels: Call logs loaded successfully');
    } catch (e, stackTrace) {
      print('GestionAppels: Error loading call logs: $e');
      print('Stack trace: $stackTrace');

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _applyFilters() {
    List<CallLogEntry> filtered = _callLogs;

    // Apply call type filter
    if (_filterType == 'incoming') {
      filtered = filtered
          .where((call) => call.callType == CallType.incoming)
          .toList();
    } else if (_filterType == 'outgoing') {
      filtered = filtered
          .where((call) => call.callType == CallType.outgoing)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((call) {
        final number = call.number?.toLowerCase() ?? '';
        final name = call.name?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return number.contains(query) || name.contains(query);
      }).toList();
    }

    setState(() {
      _filteredCallLogs = filtered;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _filterType = filter;
    });
    _applyFilters();
  }

  void _makeCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) return;

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de passer l\'appel')),
        );
      }
    }
  }

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
        // Navigate to Messagerie
        Navigator.pushReplacementNamed(context, AppRoutes.messagerie);
        break;
      case 2:
        // Already on Gestion des appels
        setState(() {
          _selectedIndex = 2;
        });
        break;
      case 3:
        // Navigate to Agent Terrain
        Navigator.pushReplacementNamed(context, AppRoutes.agentTerrain);
        break;
    }
  }

  String _formatDateTime(int? timestamp) {
    if (timestamp == null) return 'Inconnu';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Hier ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      return DateFormat('dd MMM yyyy HH:mm').format(dateTime);
    }
  }

  String _formatDuration(int? duration) {
    if (duration == null || duration == 0) return 'N/A';

    final minutes = duration ~/ 60;
    final seconds = duration % 60;

    if (minutes > 0) {
      return '${minutes}min ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _getCallTypeText(CallType callType) {
    switch (callType) {
      case CallType.incoming:
        return 'Entrant';
      case CallType.outgoing:
        return 'Sortant';
      case CallType.missed:
        return 'Manqué';
      case CallType.rejected:
        return 'Rejeté';
      default:
        return 'Appel';
    }
  }

  Color _getCallTypeColor(CallType callType) {
    switch (callType) {
      case CallType.incoming:
        return const Color(0xFF4CAF50); // Green for incoming
      case CallType.outgoing:
        return const Color(0xFF2196F3); // Blue for outgoing
      case CallType.missed:
      case CallType.rejected:
        return const Color(0xFFFF5252); // Red for missed calls
      default:
        return Colors.grey;
    }
  }

  IconData _getCallIcon(CallType callType) {
    switch (callType) {
      case CallType.incoming:
        return Icons.call_received;
      case CallType.outgoing:
        return Icons.call_made;
      case CallType.missed:
      case CallType.rejected:
        return Icons.phone_missed;
      default:
        return Icons.phone;
    }
  }

  Widget _buildCallCard(CallLogEntry call) {
    final bool isMissed =
        call.callType == CallType.missed || call.callType == CallType.rejected;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Call type icon
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: _getCallTypeColor(call.callType!).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCallIcon(call.callType!),
              color: _getCallTypeColor(call.callType!),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Call details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.name ?? call.number ?? 'Inconnu',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (call.name != null && call.number != null)
                  Text(
                    call.number!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _getCallTypeText(call.callType!),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getCallTypeColor(call.callType!),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: Colors.grey.shade400)),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(call.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Duration display
                Text(
                  isMissed
                      ? 'Durée: N/A'
                      : 'Durée: ${_formatDuration(call.duration)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Call action button
          GestureDetector(
            onTap: () => _makeCall(call.number),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        _onFilterChanged(value);
      },
      selectedColor: const Color(0xFF6366F1),
      backgroundColor: Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Widget _buildBody() {
    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_locked, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Permission requise',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Accordez l\'autorisation pour afficher l\'historique des appels',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _requestPermission();
                if (_hasPermission) {
                  await _loadCallLogs();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Demander l\'autorisation'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF6366F1)),
      );
    }

    if (_filteredCallLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _filterType != 'all'
                  ? 'Aucun résultat'
                  : 'Aucun appel trouvé',
              style: const TextStyle(fontSize: 18, color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou numéro...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildFilterChip('Tous', 'all', Icons.history),
              const SizedBox(width: 8),
              _buildFilterChip('Entrant', 'incoming', Icons.call_received),
              const SizedBox(width: 8),
              _buildFilterChip('Sortant', 'outgoing', Icons.call_made),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_filteredCallLogs.length} appel(s)',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Call logs list
        Expanded(
          child: ListView.builder(
            itemCount: _filteredCallLogs.length,
            itemBuilder: (context, index) {
              return _buildCallCard(_filteredCallLogs[index]);
            },
          ),
        ),
      ],
    );
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
              'Gestion des appels',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _hasPermission ? _loadCallLogs : null,
              ),
            ],
          ),
        ),
        body: SafeArea(child: _buildBody()),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 15.0, right: 5.0),
          child: FloatingActionButton(
            onPressed: () async {
              // Open phone dialer directly
              final Uri phoneUri = Uri(scheme: 'tel', path: '');
              if (await canLaunchUrl(phoneUri)) {
                await launchUrl(phoneUri);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Impossible d\'ouvrir le composeur'),
                    ),
                  );
                }
              }
            },
            backgroundColor: const Color(0xFF4CAF50),
            elevation: 8,
            child: const Icon(Icons.dialpad, color: Colors.white, size: 30),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
}
