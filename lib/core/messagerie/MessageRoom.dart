import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cryptoimmobilierapp/providers/auth_provider.dart';
import 'package:cryptoimmobilierapp/providers/messaging_provider.dart';
import 'package:cryptoimmobilierapp/models/RoomModel.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class MessageRoomPage extends StatefulWidget {
  final RoomModel room;

  const MessageRoomPage({Key? key, required this.room}) : super(key: key);

  @override
  State<MessageRoomPage> createState() => _MessageRoomPageState();
}

class _MessageRoomPageState extends State<MessageRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isRecording = false;
  bool _isLoadingMessages = true;
  bool _isSendingMessage = false;
  String? _recordingPath;
  int _recordingDuration = 0;
  String? _currentlyPlayingMessageId;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());
    _initializeRoom();
  }

  Future<void> _initializeRoom() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );

    final token = authProvider.token;
    if (token != null) {
      // Join room for Socket.IO updates
      messagingProvider.joinRoom(widget.room.id);

      // Fetch messages
      await messagingProvider.fetchRoomMessages(
        token: token,
        roomId: widget.room.id,
      );

      // Mark messages as seen
      await messagingProvider.markMessagesAsSeen(
        token: token,
        roomId: widget.room.id,
      );
    }

    setState(() {
      _isLoadingMessages = false;
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _sendTextMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (!mounted) return;

    setState(() {
      _isSendingMessage = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messagingProvider = Provider.of<MessagingProvider>(
      context,
      listen: false,
    );
    final token = authProvider.token;

    if (token != null) {
      _messageController.clear();

      final success = await messagingProvider.sendTextMessage(
        token: token,
        roomId: widget.room.id,
        text: text,
      );

      if (!mounted) return;

      if (success) {
        // Scroll to bottom
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de l\'envoi du message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _isSendingMessage = false;
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path =
            '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        if (!mounted) return;

        setState(() {
          _isRecording = true;
          _recordingPath = path;
          _recordingDuration = 0;
        });

        // Update duration every second
        _updateRecordingDuration();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission microphone requise'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error starting recording: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _updateRecordingDuration() {
    if (_isRecording) {
      Future.delayed(const Duration(seconds: 1), () {
        if (_isRecording) {
          setState(() {
            _recordingDuration++;
          });
          _updateRecordingDuration();
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      if (path != null && path.isNotEmpty) {
        await _sendVoiceMessage(path);
      }
    } catch (e) {
      print('Error stopping recording: $e');
      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'arrêt de l\'enregistrement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder.stop();

      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _recordingDuration = 0;
      });

      // Delete the file
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('Error canceling recording: $e');
      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _recordingDuration = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'annulation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendVoiceMessage(String path) async {
    if (!mounted) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final messagingProvider = Provider.of<MessagingProvider>(
        context,
        listen: false,
      );
      final token = authProvider.token;

      if (token != null) {
        final file = File(path);

        // Check if file exists
        if (!await file.exists()) {
          throw Exception('Fichier audio introuvable');
        }

        final success = await messagingProvider.sendVoiceMessage(
          token: token,
          roomId: widget.room.id,
          voiceFile: file,
          duration: _recordingDuration,
        );

        if (!mounted) return;

        if (success) {
          // Delete temporary file
          if (await file.exists()) {
            await file.delete();
          }

          // Scroll to bottom
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erreur lors de l\'envoi du message vocal'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error sending voice message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
          _recordingDuration = 0;
          _recordingPath = null;
        });
      }
    }
  }

  Future<void> _playVoiceMessage(MessageModel message) async {
    try {
      if (_currentlyPlayingMessageId == message.id) {
        // Stop playing
        await _audioPlayer.stop();
        if (!mounted) return;
        setState(() {
          _currentlyPlayingMessageId = null;
        });
      } else {
        // Start playing
        final url = message.voiceUrl;
        if (url != null && url.isNotEmpty) {
          await _audioPlayer.play(UrlSource(url));
          if (!mounted) return;
          setState(() {
            _currentlyPlayingMessageId = message.id;
          });

          // Listen for completion
          _audioPlayer.onPlayerComplete.listen((_) {
            if (mounted) {
              setState(() {
                _currentlyPlayingMessageId = null;
              });
            }
          });
        }
      }
    } catch (e) {
      print('Error playing voice message: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: isMe ? 64 : 8,
          right: isMe ? 8 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF6366F1) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sender name (if not me)
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  message.sender.name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),

            // Message content
            if (message.type == 'text')
              Text(
                message.text,
                style: TextStyle(
                  color: isMe ? Colors.white : const Color(0xFF1F2937),
                  fontSize: 15,
                ),
              )
            else
              _buildVoiceMessageContent(message, isMe),

            const SizedBox(height: 4),

            // Timestamp and seen indicator
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeago.format(message.createdAt, locale: 'fr'),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : Colors.grey.shade600,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.seenBy.length > 1 ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.seenBy.length > 1
                        ? Colors.blue.shade200
                        : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceMessageContent(MessageModel message, bool isMe) {
    final isPlaying = _currentlyPlayingMessageId == message.id;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _playVoiceMessage(message),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withOpacity(0.2)
                  : const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: isMe ? Colors.white : const Color(0xFF6366F1),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 150,
              height: 3,
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withOpacity(0.3)
                    : const Color(0xFF6366F1).withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: isPlaying ? 0.5 : 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white : const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${message.voiceDuration}s',
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordingUI() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(top: BorderSide(color: Colors.red.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Enregistrement en cours...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  '${_recordingDuration}s',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _cancelRecording,
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Annuler',
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _stopRecording,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Tapez votre message...',
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Voice message button
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          GestureDetector(
            onTap: _isSendingMessage ? null : _sendTextMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _messageController.text.trim().isEmpty
                    ? Colors.grey.shade300
                    : const Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
              child: _isSendingMessage
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();

    // Leave room - but check if widget is still mounted
    // We need to leave the room before disposing, but safely
    try {
      if (mounted) {
        final messagingProvider = Provider.of<MessagingProvider>(
          context,
          listen: false,
        );
        messagingProvider.leaveRoom(widget.room.id);
      }
    } catch (e) {
      print('Error leaving room on dispose: $e');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: const Color(0xFF6366F1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.room.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${widget.room.members.length} membres',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'leave') {
                _showLeaveRoomDialog();
              } else if (value == 'info') {
                _showRoomInfo();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('Informations'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Quitter', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: Consumer<MessagingProvider>(
                builder: (context, messagingProvider, child) {
                  if (_isLoadingMessages) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                      ),
                    );
                  }

                  final messages = messagingProvider.getMessagesForRoom(
                    widget.room.id,
                  );

                  if (messages.isEmpty) {
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
                          const SizedBox(height: 16),
                          const Text(
                            'Aucun message',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Envoyez le premier message!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.sender.id == currentUserId;
                      return _buildMessageBubble(message, isMe);
                    },
                  );
                },
              ),
            ),

            // Recording UI or Message input
            if (_isRecording) _buildRecordingUI() else _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  void _showLeaveRoomDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quitter la conversation'),
        content: const Text(
          'Êtes-vous sûr de vouloir quitter cette conversation? '
          'Vous ne recevrez plus de messages.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final messagingProvider = Provider.of<MessagingProvider>(
                context,
                listen: false,
              );
              final token = authProvider.token;

              if (token != null) {
                final success = await messagingProvider.leaveRoomPermanently(
                  token: token,
                  roomId: widget.room.id,
                );

                if (!mounted) return;

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vous avez quitté la conversation'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Erreur lors de la sortie'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRoomInfo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  child: Text(
                    widget.room.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.room.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Créé ${timeago.format(widget.room.createdAt, locale: 'fr')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Membres',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...widget.room.members.map((member) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  child: Text(
                    member.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(member.name),
                subtitle: Text(member.role),
                trailing: widget.room.creator.id == member.id
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Créateur',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : null,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
