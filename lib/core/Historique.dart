import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:cryptoimmobilierapp/utils/Routes.dart';

class HistoriquePage extends StatefulWidget {
  const HistoriquePage({Key? key}) : super(key: key);

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> {
  int _selectedIndex = 2; // Set to 2 for "Historique" tab
  List<CallLogEntry> _callLogs = [];
  bool _isLoading = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadLogs();
  }

  Future<void> _checkPermissionAndLoadLogs() async {
    try {
      print('Historique: Checking permission...');
      final phoneStatus = await Permission.phone.status;
      print('Historique: Permission status: $phoneStatus');

      setState(() {
        _hasPermission = phoneStatus.isGranted;
      });

      if (phoneStatus.isGranted) {
        print('Historique: Permission granted, loading call logs...');
        await _loadCallLogs();
      } else if (phoneStatus.isDenied) {
        print('Historique: Permission denied, requesting...');
        await _requestPermission();
        if (_hasPermission) {
          await _loadCallLogs();
        }
      } else if (phoneStatus.isPermanentlyDenied) {
        print('Historique: Permission permanently denied');
        _showPermissionDialog();
      }
    } catch (e, stackTrace) {
      print('Historique: Error in checkPermissionAndLoadLogs: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _hasPermission = false;
      });
    }
  }

  Future<void> _requestPermission() async {
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
      print('Historique: No permission to load call logs');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Historique: Fetching call logs...');
      // Limit to last 100 call logs for better performance
      final Iterable<CallLogEntry> logs = await CallLog.query(
        dateFrom: DateTime.now()
            .subtract(const Duration(days: 30))
            .millisecondsSinceEpoch,
        dateTo: DateTime.now().millisecondsSinceEpoch,
      );

      // Take only the first 100 entries
      final limitedLogs = logs.take(100).toList();
      print('Historique: Fetched ${limitedLogs.length} call logs');

      setState(() {
        _callLogs = limitedLogs;
        _isLoading = false;
      });
      print('Historique: Call logs loaded successfully');
    } catch (e, stackTrace) {
      print('Historique: Error loading call logs: $e');
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
        // Navigate to Call
        Navigator.pushReplacementNamed(context, AppRoutes.call);
        break;
      case 2:
        // Already on Historique
        setState(() {
          _selectedIndex = 2;
        });
        break;
      case 3:
        // Navigate to Gestion des appels (to be implemented)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gestion des appels - à venir')),
        );
        break;
    }
  }

  String _formatDateTime(int? timestamp) {
    if (timestamp == null) return 'Inconnu';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  String _formatDuration(int? duration) {
    if (duration == null || duration == 0) return 'N/A';

    final minutes = duration ~/ 60;
    final seconds = duration % 60;

    if (minutes > 0) {
      return 'Durée : ${minutes}min${seconds}s';
    } else {
      return 'Durée : ${seconds}s';
    }
  }

  String _getCallTypeText(CallType callType) {
    switch (callType) {
      case CallType.incoming:
        return 'Appel entrant';
      case CallType.outgoing:
        return 'Appel sortant';
      case CallType.missed:
        return 'Appel manqué';
      case CallType.rejected:
        return 'Appel rejeté';
      default:
        return 'Appel';
    }
  }

  Color _getCallTypeColor(CallType callType) {
    switch (callType) {
      case CallType.incoming:
      case CallType.outgoing:
        return const Color(0xFF4CAF50); // Green for successful calls
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
      case CallType.outgoing:
        return Icons.phone;
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call.number ?? 'Inconnu',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(call.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  call.simDisplayName ?? 'Téléphone',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getCallTypeText(call.callType!),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _getCallIcon(call.callType!),
                      color: _getCallTypeColor(call.callType!),
                      size: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (!isMissed)
                Text(
                  _formatDuration(call.duration),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
            ],
          ),
        ],
      ),
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
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Accordez l\'autorisation pour afficher l\'historique des appels',
                style: TextStyle(color: Colors.grey),
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

    if (_callLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Aucun appel trouvé',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _callLogs.length,
            itemBuilder: (context, index) {
              return _buildCallCard(_callLogs[index]);
            },
          ),
          const SizedBox(height: 100), // Extra space for navigation bar
        ],
      ),
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
              'Historique des appels',
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
                selectedFontSize: 9,
                unselectedFontSize: 8,
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
                    icon: Icon(Icons.call_outlined),
                    activeIcon: Icon(Icons.call),
                    label: 'Appel',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.schedule_outlined),
                    activeIcon: Icon(Icons.schedule),
                    label: 'Historique',
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
