import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cryptoimmobilierapp/providers/auth_provider.dart';
import 'package:cryptoimmobilierapp/providers/messaging_provider.dart';
import 'package:cryptoimmobilierapp/models/RoomModel.dart';
import 'package:cryptoimmobilierapp/api/api_endpoints.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

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
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();
  late final RecorderController _recorderController;
  final Map<String, PlayerController> _playerControllers = {};
  StreamSubscription<void>? _audioPlayerCompleteSubscription;

  bool _isRecording = false;
  bool _isLoadingMessages = true;
  bool _isSendingMessage = false;
  String? _recordingPath;
  int _recordingDuration = 0;
  String? _currentlyPlayingMessageId;
  int _previousMessageCount = 0;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('fr', timeago.FrMessages());

    // Initialize waveform recorder controller with better quality settings
    _recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100
      ..bitRate = 128000;

    // Listen for audio player state changes
    _audioPlayer.onPlayerStateChanged.listen((ap.PlayerState state) {
      print('🎵 Audio player state changed: $state');
      if (state == ap.PlayerState.completed) {
        print('✅ Playback completed - stopping player');
        if (mounted) {
          setState(() {
            _currentlyPlayingMessageId = null;
          });
        }
      }
    });

    // Listen for audio player completion - store subscription to cancel later
    _audioPlayerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((
      _,
    ) {
      print('🎵 Audio player onComplete event fired');
      if (mounted) {
        setState(() {
          _currentlyPlayingMessageId = null;
        });
        print('✅ Audio playback stopped and UI updated');
      }
    });

    // Listen to text field changes to update send button color
    _messageController.addListener(() {
      setState(() {
        // This will trigger rebuild to update send button color
      });
    });

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
      print('🔍 Checking microphone permission...');

      // Check microphone permission status first
      final micStatus = await Permission.microphone.status;
      print('  Microphone status: $micStatus');

      // Request permission if not already granted
      if (!micStatus.isGranted) {
        print('  Requesting microphone permission...');
        final result = await Permission.microphone.request();
        print('  Permission result: $result');

        if (!result.isGranted) {
          print('❌ Microphone permission denied by user');
          if (!mounted) return;

          // Show different message for permanently denied
          if (result.isPermanentlyDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Permission microphone refusée définitivement. Veuillez l\'activer dans les paramètres de l\'application.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Ouvrir Paramètres',
                  textColor: Colors.white,
                  onPressed: () => openAppSettings(),
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Permission microphone requise pour enregistrer des messages vocaux.',
                ),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      print('✅ Microphone permission granted');

      // Check storage permission for Android 12 and below
      if (Platform.isAndroid) {
        final storageStatus = await Permission.storage.status;
        print('  Storage status: $storageStatus');

        if (!storageStatus.isGranted) {
          print('  Requesting storage permission...');
          final result = await Permission.storage.request();
          print('  Storage permission result: $result');
        }
      }

      // Double check with audio recorder
      final hasPermission = await _audioRecorder.hasPermission();
      print('  Audio recorder hasPermission: $hasPermission');

      if (!hasPermission) {
        print('❌ Audio recorder reports no permission');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Permission microphone non disponible'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Permission granted, start recording
      print('✅ All permissions granted, starting recording...');

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      print('🎙️ Recording to: $path');
      print('  Directory exists: ${await directory.exists()}');

      // Start both audio recorder and waveform recorder
      await Future.wait([
        _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
            numChannels: 1, // Mono for voice
            autoGain: true, // Auto gain control
            echoCancel: true, // Echo cancellation
            noiseSuppress: true, // Noise suppression
          ),
          path: path,
        ),
        _recorderController.record(path: path),
      ]);

      print('✅ Recording started successfully');
      print('  Is recording: ${await _audioRecorder.isRecording()}');
      print('  Waveform recording: ${_recorderController.isRecording}');

      if (!mounted) return;

      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _recordingDuration = 0;
      });

      // Update duration every second
      _updateRecordingDuration();
    } catch (e) {
      print('❌ Error starting recording: $e');
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
      print('⏹️ Stopping recording...');

      // Stop both audio recorder and waveform recorder
      final results = await Future.wait([
        _audioRecorder.stop(),
        _recorderController.stop(),
      ]);

      final path = results[0];
      print('  Recorded file path: $path');

      if (!mounted) return;

      setState(() {
        _isRecording = false;
      });

      if (path != null && path.isNotEmpty) {
        // Check file size to verify audio was captured
        final file = File(path);
        if (await file.exists()) {
          final fileSize = await file.length();
          print('  File size: ${fileSize} bytes');

          if (fileSize < 1000) {
            print('⚠️ Warning: File size is very small, might be empty/silent');
          }
        }

        await _sendVoiceMessage(path);
      } else {
        print('❌ No recording path returned');
      }
    } catch (e) {
      print('❌ Error stopping recording: $e');
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
      // Stop both recorders
      await Future.wait([
        _audioRecorder.stop(),
        _recorderController.stop(false), // false = don't save the file
      ]);

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
        print('⏸️ Audio playback stopped');
      } else {
        // Stop any currently playing audio first
        if (_currentlyPlayingMessageId != null) {
          await _audioPlayer.stop();
        }

        // Start playing
        final voiceUrl = message.voiceUrl;
        if (voiceUrl != null && voiceUrl.isNotEmpty) {
          // Construct full URL if it's a relative path
          final fullUrl = voiceUrl.startsWith('http')
              ? voiceUrl
              : '${ApiEndpoints.baseUrl}$voiceUrl';

          print('🔊 Playing voice message from: $fullUrl');

          await _audioPlayer.play(ap.UrlSource(fullUrl));
          if (!mounted) return;
          setState(() {
            _currentlyPlayingMessageId = message.id;
          });

          print('✅ Voice message playing');
        }
      }
    } catch (e) {
      print('❌ Error playing voice message: $e');
      if (!mounted) return;
      setState(() {
        _currentlyPlayingMessageId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lecture audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Profile picture for other users (left side)
          if (!isMe) ...[
            _buildProfilePicture(message.sender),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                top: 2,
                bottom: 2,
                left: isMe ? 64 : 0,
                right: isMe ? 0 : 64,
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
                          message.seenBy.length > 1
                              ? Icons.done_all
                              : Icons.done,
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
          ),

          // Profile picture for current user (right side)
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildProfilePicture(message.sender),
          ],
        ],
      ),
    );
  }

  Widget _buildProfilePicture(UserBasic user) {
    final hasProfilePhoto =
        user.profilePhoto != null && user.profilePhoto!.url != null;

    return CircleAvatar(
      radius: 16,
      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
      backgroundImage: hasProfilePhoto
          ? NetworkImage(
              user.profilePhoto!.url!.startsWith('http')
                  ? user.profilePhoto!.url!
                  : '${ApiEndpoints.baseUrl}${user.profilePhoto!.url!}',
            )
          : null,
      child: !hasProfilePhoto
          ? Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            )
          : null,
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Waveform-style visualization
              SizedBox(
                height: 35,
                width: 150,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(25, (index) {
                    // Create varied heights for waveform effect
                    final heights = [
                      0.3,
                      0.5,
                      0.8,
                      1.0,
                      0.7,
                      0.4,
                      0.6,
                      0.9,
                      0.5,
                      0.3,
                    ];
                    final heightFactor = heights[index % heights.length];

                    return Container(
                      width: 2.5,
                      height: 35 * heightFactor,
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withOpacity(0.5)
                            : const Color(0xFF6366F1).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${message.voiceDuration ?? 0}s',
                style: TextStyle(
                  fontSize: 12,
                  color: isMe ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
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
                Row(
                  children: [
                    const Text(
                      'Enregistrement',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_recordingDuration}s',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Waveform visualization
                SizedBox(
                  height: 40,
                  child: AudioWaveforms(
                    size: Size(MediaQuery.of(context).size.width - 200, 40),
                    recorderController: _recorderController,
                    enableGesture: false,
                    waveStyle: WaveStyle(
                      waveColor: Colors.red,
                      extendWaveform: true,
                      showMiddleLine: false,
                      scaleFactor: 100,
                      waveThickness: 3,
                    ),
                  ),
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
    _recorderController.dispose();

    // Cancel audio player completion subscription
    _audioPlayerCompleteSubscription?.cancel();

    // Dispose all player controllers
    for (var controller in _playerControllers.values) {
      controller.dispose();
    }
    _playerControllers.clear();

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

                  // Auto-scroll to bottom when new messages arrive
                  if (messages.length > _previousMessageCount) {
                    _previousMessageCount = messages.length;
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
              final hasProfilePhoto = member.profilePhoto != null &&
                  member.profilePhoto!.url != null;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                  backgroundImage: hasProfilePhoto
                      ? NetworkImage(
                          member.profilePhoto!.url!.startsWith('http')
                              ? member.profilePhoto!.url!
                              : '${ApiEndpoints.baseUrl}${member.profilePhoto!.url!}',
                        )
                      : null,
                  child: !hasProfilePhoto
                      ? Text(
                          member.name[0].toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
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
