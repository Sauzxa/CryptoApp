import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:CryptoApp/utils/Routes.dart';
import 'package:CryptoApp/providers/auth_provider.dart';
import '../utils/colors.dart';
import '../api/api_client.dart';
import 'Rendez-vous/ReserverRendezVous.dart';

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
      final phoneStatus = await Permission.phone.status;

      setState(() {
        _hasPermission = phoneStatus.isGranted;
      });

      if (phoneStatus.isGranted) {
        await _loadCallLogs();
      } else if (phoneStatus.isDenied) {
        await _requestPermission();
        if (_hasPermission) {
          await _loadCallLogs();
        }
      } else if (phoneStatus.isPermanentlyDenied) {
        _showPermissionDialog();
      }
    } catch (e) {
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
    if (!_hasPermission) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final Iterable<CallLogEntry> logs = await CallLog.query(
        dateFrom: DateTime.now()
            .subtract(const Duration(days: 30))
            .millisecondsSinceEpoch,
        dateTo: DateTime.now().millisecondsSinceEpoch,
      );

      final limitedLogs = logs.take(100).toList();

      setState(() {
        _callLogs = limitedLogs;
        _filteredCallLogs = limitedLogs;
        _isLoading = false;
      });
      _applyFilters();

      // Auto-sync to backend after loading
      _syncCallsToBackend();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _syncCallsToBackend() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null || _callLogs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _callLogs.isEmpty
                  ? 'Aucun appel à synchroniser'
                  : 'Non authentifié',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      List<Map<String, dynamic>> callLogsToSync = _callLogs.map((call) {
        String direction = 'outgoing';
        if (call.callType == CallType.incoming) {
          direction = 'incoming';
        } else if (call.callType == CallType.missed ||
            call.callType == CallType.rejected) {
          direction = 'missed';
        }

        return {
          'direction': direction,
          'phoneNumber': call.number ?? 'Unknown',
          'startedAt': DateTime.fromMillisecondsSinceEpoch(
            call.timestamp ?? 0,
          ).toIso8601String(),
          'endedAt': call.duration != null && call.duration! > 0
              ? DateTime.fromMillisecondsSinceEpoch(
                  (call.timestamp ?? 0) + (call.duration! * 1000),
                ).toIso8601String()
              : null,
          'durationSec': call.duration ?? 0,
          'note': call.name,
        };
      }).toList();

      final response = await apiClient.syncMultipleCallLogs(
        token: token,
        callLogs: callLogsToSync,
      );

      if (response.success && mounted) {
        final synced = response.data?['synced'] ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $synced appels synchronisés'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${response.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur de synchronisation'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
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

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
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
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0A192F) // Dark blue background
            : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Colors.white.withOpacity(0.1), width: 1)
            : null,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: Theme.of(context).brightness == Brightness.dark
                ? 15
                : 5,
            offset: const Offset(0, 2),
            spreadRadius: Theme.of(context).brightness == Brightness.dark
                ? 1
                : 0,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (call.name != null && call.number != null)
                  Text(
                    call.number!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey.shade300
                          : Colors.grey.shade600,
                    ),
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
                    Text(
                      '•',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateTime(call.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
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
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Call button
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
              const SizedBox(height: 8),
              // Create reservation button
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ReserverRendezVousPage(phoneNumber: call.number),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
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
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? Colors.white
                : Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade300
                : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        _onFilterChanged(value);
      },
      selectedColor: const Color(0xFF6366F1),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey.shade800
          : Colors.grey.shade200,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black87,
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

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou numéro...',
              hintStyle: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.6)
                    : Colors.grey.shade600,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF6366F1),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF6366F1),
                      ),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.white,
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
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey.shade300
                    : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Call logs list or empty state
        Expanded(
          child: _filteredCallLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty || _filterType != 'all'
                            ? Icons.search_off
                            : Icons.phone,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty || _filterType != 'all'
                            ? 'Aucun résultat trouvé'
                            : 'Aucun appel récent',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_searchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Aucun contact ne correspond à "$_searchQuery"',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
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
    return Scaffold(
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
                  Icons.arrow_back,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Text(
                'Gestion des appels',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: _hasPermission ? _loadCallLogs : null,
                  tooltip: 'Actualiser',
                ),
              ],
            ),
          ),
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
}
