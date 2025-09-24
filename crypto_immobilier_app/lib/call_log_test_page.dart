import 'package:flutter/material.dart';
import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class CallLogTestPage extends StatefulWidget {
  const CallLogTestPage({super.key});

  @override
  State<CallLogTestPage> createState() => _CallLogTestPageState();
}

class _CallLogTestPageState extends State<CallLogTestPage> {
  int _currentIndex = 0;
  List<CallLogEntry> _callLogs = [];
  bool _isLoading = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoadLogs();
  }

  Future<void> _checkPermissionAndLoadLogs() async {
    await _requestPermission();
    if (_hasPermission) {
      await _loadCallLogs();
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.phone.request();
    setState(() {
      _hasPermission = status.isGranted;
    });

    if (!_hasPermission) {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'This app needs access to phone logs to display call history. '
          'Please grant permission in the app settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCallLogs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Iterable<CallLogEntry> logs = await CallLog.get();
      setState(() {
        _callLogs = logs.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load call logs: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _makeTestCall() async {
    const testNumber = 'tel:+1234567890';
    try {
      final Uri launchUri = Uri.parse(testNumber);
      await launchUrl(launchUri);

      // Show instructions
      _showTestCallDialog();
    } catch (e) {
      _showError('Failed to make test call: $e');
    }
  }

  void _showTestCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Call Instructions'),
        content: const Text(
          'A test call to +1234567890 has been initiated.\n\n'
          'After ending the call, press the refresh button to see if the call '
          'appears in the call history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<CallLogEntry> _getFilteredCalls() {
    if (_currentIndex == 0) {
      // Historique - show all calls
      return _callLogs;
    } else {
      // Input/Output - show only incoming and outgoing (exclude missed/rejected)
      return _callLogs
          .where((call) =>
              call.callType == CallType.incoming ||
              call.callType == CallType.outgoing)
          .toList();
    }
  }

  Widget _buildCallIcon(CallType callType) {
    switch (callType) {
      case CallType.incoming:
        return const Icon(Icons.call_received, color: Colors.green, size: 20);
      case CallType.outgoing:
        return const Icon(Icons.call_made, color: Colors.blue, size: 20);
      case CallType.missed:
        return const Icon(Icons.call_received, color: Colors.red, size: 20);
      case CallType.rejected:
        return const Icon(Icons.call_end, color: Colors.red, size: 20);
      default:
        return const Icon(Icons.call, color: Colors.grey, size: 20);
    }
  }

  String _getCallTypeText(CallType callType) {
    switch (callType) {
      case CallType.incoming:
        return '📥 Incoming';
      case CallType.outgoing:
        return '📤 Outgoing';
      case CallType.missed:
        return '❌ Missed';
      case CallType.rejected:
        return '🚫 Rejected';
      default:
        return '📞 Unknown';
    }
  }

  String _formatDuration(int? duration) {
    if (duration == null || duration == 0) return 'N/A';

    final minutes = duration ~/ 60;
    final seconds = duration % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDateTime(int? timestamp) {
    if (timestamp == null) return 'Unknown';

    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  Widget _buildCallList() {
    if (!_hasPermission) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_locked, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Phone permission required',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Grant phone permission to view call logs',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredCalls = _getFilteredCalls();

    if (filteredCalls.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No call logs found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredCalls.length,
      itemBuilder: (context, index) {
        final call = filteredCalls[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: _buildCallIcon(call.callType!),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    call.name?.isNotEmpty == true
                        ? call.name!
                        : call.number ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  _getCallTypeText(call.callType!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (call.number != null && call.name?.isNotEmpty == true)
                  Text(
                    call.number!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDateTime(call.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Text(
                      'Duration: ${_formatDuration(call.duration)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildInputOutputView() {
    if (!_hasPermission) {
      return _buildCallList();
    }

    final incomingCalls =
        _callLogs.where((call) => call.callType == CallType.incoming).toList();
    final outgoingCalls =
        _callLogs.where((call) => call.callType == CallType.outgoing).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: '📥 Incoming'),
              Tab(text: '📤 Outgoing'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSpecificCallList(incomingCalls),
                _buildSpecificCallList(outgoingCalls),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificCallList(List<CallLogEntry> calls) {
    if (calls.isEmpty) {
      return const Center(
        child: Text(
          'No calls found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: calls.length,
      itemBuilder: (context, index) {
        final call = calls[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: _buildCallIcon(call.callType!),
            ),
            title: Text(
              call.name?.isNotEmpty == true
                  ? call.name!
                  : call.number ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (call.number != null && call.name?.isNotEmpty == true)
                  Text(
                    call.number!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatDateTime(call.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(call.duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Historique' : 'Input / Output'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _hasPermission ? _loadCallLogs : null,
            tooltip: 'Refresh call logs',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Crypto Immobilier',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Call Log Test',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings - Coming Soon')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logout - Coming Soon')),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              subtitle: const Text('Call Log Test v1.0'),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'Crypto Immobilier',
                  applicationVersion: '1.0.0',
                  children: [
                    const Text('Call log extraction test for real estate app.'),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: _currentIndex == 0 ? _buildCallList() : _buildInputOutputView(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Historique',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Input / Output',
          ),
        ],
      ),
      floatingActionButton: _hasPermission
          ? FloatingActionButton.extended(
              onPressed: _makeTestCall,
              backgroundColor: Colors.green,
              icon: const Icon(Icons.phone, color: Colors.white),
              label: const Text(
                'Test Call',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
