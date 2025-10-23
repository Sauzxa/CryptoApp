import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:CryptoApp/utils/Routes.dart';
import 'package:CryptoApp/providers/auth_provider.dart';
import 'package:CryptoApp/providers/messaging_provider.dart';
import 'package:CryptoApp/core/messagerie/CreateRoomPage.dart';
import 'package:CryptoApp/core/messagerie/MessageRoom.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import '../utils/colors.dart';

class MessageriePage extends StatefulWidget {
  const MessageriePage({Key? key}) : super(key: key);

  @override
  State<MessageriePage> createState() => _MessageriePageState();
}

class _MessageriePageState extends State<MessageriePage> {
  int _selectedIndex = 1; // Set to 1 for "Messagerie" tab
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Configure timeago for French
    timeago.setLocaleMessages('fr', timeago.FrMessages());

    // Load rooms after the first frame to avoid provider access during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRooms();
    });
  }

  Future<void> _loadRooms() async {
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );

    final token = authProvider.token;
    if (token != null) {
      await messagingProvider.fetchRooms(token);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
        // Already on Messagerie
        setState(() {
          _selectedIndex = 1;
        });
        break;
      case 2:
        // Navigate to Gestion des appels
        Navigator.pushReplacementNamed(context, AppRoutes.gestionAppels);
        break;
      case 3:
        // Navigate to Agent Terrain
        Navigator.pushReplacementNamed(context, AppRoutes.agentTerrain);
        break;
    }
  }

  IconData _getCommercialActionIcon(String? action) {
    // Use the same logic as ReservationModel
    if (action == 'paye') {
      return Icons.check_circle;
    } else if (action == 'en_cours') {
      return Icons.schedule;
    } else if (action == 'annulee') {
      return Icons.cancel;
    } else {
      return Icons.schedule; // Default to "En Cours" icon
    }
  }

  Widget _buildRoomCard(room) {
    final lastMessage = room.lastMessage;
    final timeAgo = lastMessage != null
        ? timeago.format(lastMessage.createdAt, locale: 'fr')
        : timeago.format(room.createdAt, locale: 'fr');

    // Check if this is a reservation room
    final isReservationRoom =
        room.roomType == 'reservation' && room.reservationId != null;

    // Get commercial action color and text (using same logic as ReservationModel)
    Color commercialActionColor = Colors.grey;
    String commercialActionText = '';

    if (isReservationRoom) {
      // Use the same logic as ReservationModel.commercialActionDisplay
      if (room.commercialAction == 'paye') {
        commercialActionText = 'Payé';
        commercialActionColor = Colors.green;
      } else if (room.commercialAction == 'en_cours') {
        commercialActionText = 'En Cours';
        commercialActionColor = Colors.orange;
      } else if (room.commercialAction == 'annulee') {
        commercialActionText = 'Annulé';
        commercialActionColor = Colors.red;
      } else {
        // Default state when no commercial action is set
        commercialActionText = 'En Cours';
        commercialActionColor = Colors.orange;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0A192F) // Dark blue background
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                : 10,
            offset: const Offset(0, 2),
            spreadRadius: Theme.of(context).brightness == Brightness.dark
                ? 1
                : 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to chat room
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MessageRoomPage(room: room),
              ),
            ).then((_) {
              // Reload rooms when returning
              _loadRooms();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Room Avatar
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                      child: Text(
                        room.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Room Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Client name (prominent)
                          if (isReservationRoom &&
                              room.clientFullName != null) ...[
                            Text(
                              room.clientFullName!,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                          ] else ...[
                            // Fallback to room name for non-reservation rooms
                            Text(
                              room.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white
                                    : const Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                          ],

                          // Commercial Action and Time
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Commercial Action Badge
                              if (isReservationRoom &&
                                  room.commercialAction != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: commercialActionColor.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: commercialActionColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    commercialActionText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: commercialActionColor,
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Show clean message preview for non-reservation rooms (no JSON)
                                Expanded(
                                  child: Text(
                                    lastMessage != null
                                        ? (lastMessage.type == 'voice'
                                              ? '🎤 Message vocal'
                                              : lastMessage.type == 'rapport'
                                              ? '📋 Rapport soumis'
                                              : lastMessage.text.length > 30
                                              ? '${lastMessage.text.substring(0, 30)}...'
                                              : lastMessage.text)
                                        : '${room.members.length} membres',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],

                              // Time and Date
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    timeAgo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey.shade300
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  if (isReservationRoom &&
                                      room.createdAt != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat(
                                        'dd/MM/yyyy HH:mm',
                                      ).format(room.createdAt!),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color:
                                            Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Commercial Action State for reservation rooms
                if (isReservationRoom) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _getCommercialActionIcon(room.commercialAction),
                        size: 14,
                        color: commercialActionColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'État: $commercialActionText',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: commercialActionColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context) {
    // Navigate to CreateRoomPage
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateRoomPage()),
    ).then((_) {
      // Reload rooms when returning from create page
      _loadRooms();
    });
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
                'Messagerie',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Consumer<MessagingProvider>(
          builder: (context, messagingProvider, child) {
            if (_isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              );
            }

            final rooms = messagingProvider.rooms;

            if (rooms.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Aucune conversation',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Créez une nouvelle conversation\npour commencer',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _showCreateRoomDialog(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Nouvelle conversation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadRooms,
                    color: const Color(0xFF6366F1),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return _buildRoomCard(room);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
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
