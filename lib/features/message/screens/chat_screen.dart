import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/core/constants/app_assets.dart';
import 'package:skin_app_migration/core/extensions/provider_extensions.dart';
import 'package:skin_app_migration/core/theme/app_styles.dart';
import 'package:skin_app_migration/core/widgets/k_background_scaffold.dart';
import 'package:skin_app_migration/features/message/models/chat_message_model.dart';
import 'package:skin_app_migration/features/message/provider/chat_provider.dart';
import 'package:skin_app_migration/features/message/widgets/chat_bubble.dart';

import '../../auth/providers/my_auth_provider.dart';
import '../widgets/message_text_field.dart';
import 'image_preview_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];
  final List<DocumentSnapshot> _documents = [];
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  static const int _pageSize = 20;
  StreamSubscription<List<ChatMessageModel>>? _messagesStream;

  @override
  void initState() {
    super.initState();
    _initializeStreamPagination();
    _setupScrollListener();
  }

  void _initializeStreamPagination() {
    // Start listening to real-time messages using provider
    _startMessagesStream();

    // Load initial messages
    _loadInitialMessages();
  }

  void _startMessagesStream() {
    final chatProvider = context.read<ChatProvider>();

    _messagesStream = chatProvider
        .getMessagesStream(limit: _pageSize)
        .listen(
          (List<ChatMessageModel> messages) {
            _handleStreamUpdate(messages);
          },
          onError: (error) {
            debugPrint('❌ Stream error: $error');
          },
        );
  }

  void _handleStreamUpdate(List<ChatMessageModel> messages) {
    if (!mounted) return;

    setState(() {
      _messages.clear();
      _messages.addAll(messages);

      // Update pagination state based on message count
      _hasMoreMessages = messages.length >= _pageSize;
    });
  }

  Future<void> _loadInitialMessages() async {
    if (!mounted) return;

    setState(() => _isLoadingMore = true);

    try {
      // Sync with provider's local messages first
      final chatProvider = context.read<ChatProvider>();
      await chatProvider.syncNewMessagesFromFirestore();

      // Load initial batch using provider method with document tracking
      final result = await chatProvider.getPaginatedMessagesWithDocs(
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(result['messages'] as List<ChatMessageModel>);
          _documents.clear();
          _documents.addAll(result['documents'] as List<DocumentSnapshot>);
          _hasMoreMessages = result['hasMore'] as bool;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading initial messages: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoadingMore &&
          _hasMoreMessages) {
        _loadMoreMessages();
      }
    });
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _documents.isEmpty) return;

    setState(() => _isLoadingMore = true);

    try {
      final chatProvider = context.read<ChatProvider>();

      // Use the last document for pagination
      final lastDocument = _documents.last;

      final result = await chatProvider.getPaginatedMessagesWithDocs(
        startAfter: lastDocument,
        limit: _pageSize,
      );

      if (mounted &&
          (result['messages'] as List<ChatMessageModel>).isNotEmpty) {
        setState(() {
          _messages.addAll(result['messages'] as List<ChatMessageModel>);
          _documents.addAll(result['documents'] as List<DocumentSnapshot>);
          _hasMoreMessages = result['hasMore'] as bool;
        });
      } else if (mounted) {
        setState(() => _hasMoreMessages = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading more messages: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  @override
  void dispose() {
    _messagesStream?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Consumer2<ChatProvider, MyAuthProvider>(
        builder: (context, chatProvider, myAuthProvider, child) {
          ///Handling Shared image here
          handleIntent(context);

          return KBackgroundScaffold(
            loading: context.readAuthProvider.isLoading,
            margin: const EdgeInsets.all(0),
            showDrawer: true,
            appBar: (context.readAuthProvider.userData!.isBlocked)
                ? null
                : AppBar(
                    backgroundColor: AppStyles.primary,
                    iconTheme: IconThemeData(color: AppStyles.smoke, size: 32),
                    toolbarHeight: 0.09.sh,
                    title: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CircleAvatar(
                          radius: 0.03.sh,
                          child: Image.asset(AppAssets.logo),
                        ),
                        SizedBox(width: 0.02.sw),
                        StreamBuilder<Map<String, dynamic>>(
                          stream: context
                              .readSuperAdminProvider
                              .userAndAdminCountStream,
                          builder: (context, snapshot) {
                            final employeeCount = snapshot.data?["admin"] ?? 0;
                            final candidateCount = snapshot.data?["user"] ?? 0;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "S.K.I.N. App",
                                  style: TextStyle(color: AppStyles.smoke),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "Employer: ${employeeCount.toString()}",
                                      style: TextStyle(
                                        fontSize: AppStyles.bodyText,
                                        color: AppStyles.smoke,
                                      ),
                                    ),
                                    SizedBox(width: 0.02.sw),
                                    Text(
                                      "Candidate: ${candidateCount.toString()}",
                                      style: TextStyle(
                                        fontSize: AppStyles.bodyText,
                                        color: AppStyles.smoke,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
            body: SafeArea(
              child: myAuthProvider.userData!.isBlocked
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block, color: Colors.red, size: 48),
                          SizedBox(height: 16),
                          Text(
                            "Account Blocked",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "Your account has been blocked and you cannot access the chat. Please contact support for more information.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          Center(
                            child: ElevatedButton(
                              onPressed: () async {
                                await myAuthProvider.signOut(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text("OK"),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(child: _buildMessagesList()),
                        Consumer<MyAuthProvider>(
                          builder: (context, authProvider, child) {
                            return !(authProvider.userData?.canPost ?? false)
                                ? SizedBox(height: 0.050.sh)
                                : MessageTextField(
                                    messageController:
                                        chatProvider.messageController,
                                  );
                          },
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty && !_isLoadingMore) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No messages yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true, // Show newest messages at the bottom
      itemCount: _messages.length + (_hasMoreMessages ? 1 : 0),
      itemBuilder: (context, index) {
        // Show loading indicator at the top when loading more
        if (index == _messages.length) {
          return _hasMoreMessages
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox();
        }

        // Show message
        final message = _messages[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: ChatBubble(chatMessage: message),
        );
      },
    );
  }

  void handleIntent(BuildContext context) {
    ChatProvider chatProvider = Provider.of<ChatProvider>(
      context,
      listen: false,
    );

    if (chatProvider.sharedIntentFile == null) return;
    print("handling sharing file.....");
    File _temp = chatProvider.sharedIntentFile!;
    print("pushing sharing file.....");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ImagePreviewScreen(
            image: _temp,
            initialText: chatProvider.sharedIntentText,
          ),
        ),
      );
      print("nulling sharing file.....");

      chatProvider.sharedIntentFile = null;
    });
  }
}
