import 'package:careerclaritycompanion/features/custom_widgets/confirmation_dialog.dart';
import 'package:careerclaritycompanion/features/custom_widgets/fllutter_toast.dart';
import 'package:flutter/cupertino.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; 
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:markdown/markdown.dart' as md;

class ChatScreen extends StatefulWidget {
  final String? initialPrompt;
  const ChatScreen({super.key, this.initialPrompt});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final _apiKey = dotenv.env['GEMINI_API_KEY'];
  late final GenerativeModel _model;
  String? _currentChatId;
  User? get _user => FirebaseAuth.instance.currentUser;

  // ✨ UPDATED: System instructions for the AI
  final Content _systemInstruction = Content.text("""
You are Rufi, an expert AI educational and career guide for students in India.
Your personality is encouraging, wise, and friendly.

**Your Core Directives:**
1.  **Guidance:** Provide clear, actionable advice on education, career paths, internships, etc. Remember the context of the current conversation.
2.  **Formatting:** Use Markdown for clear, readable formatting.
    - Use `##` for headings.
    - Use bullet (`* `) and numbered lists (`1. `).
    - Use `---` to create a horizontal rule.
    - Use emojis to make the content engaging (e.g., 📚, 🚀, 💡).
    - **When providing code snippets, always wrap them in fenced code blocks with the language identifier.** For example:
      ```dart
      // your dart code here
      ```
3.  **Tone:** Be polite, concise, and highly informative.
""");

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey!,
      systemInstruction: _systemInstruction,
    );
    _ensureSessionOnOpen().then((_) {
      if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
        _sendInitialPrompt(widget.initialPrompt!);
      }
    });
  }
  
  // --- All your existing methods like _sendMessage, _deleteChat, etc. remain the same ---
  // ... (Your existing _sendInitialPrompt, _ensureSessionOnOpen, _createNewChat, 
  //      _startNewChat, _sendMessage, _makeTitleFrom, _scrollToBottom, _deleteChat methods go here)
  Future<void> _sendInitialPrompt(String text) async {
    _controller.text = text;
    await _sendMessage();
  }

  Future<void> _ensureSessionOnOpen() async {
    final user = _user;
    if (user == null) return;

    final chatsCol = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chats');

    final snap =
        await chatsCol.orderBy('createdAt', descending: true).limit(1).get();

    if (snap.docs.isEmpty) {
      final newChat = await _createNewChat();
      setState(() => _currentChatId = newChat.id);
      return;
    }

    final latest = snap.docs.first;
    final latestId = latest.id;

    final msgs =
        await chatsCol.doc(latestId).collection('messages').limit(1).get();

    if (msgs.docs.isEmpty) {
      setState(() => _currentChatId = latestId);
    } else {
      final newChat = await _createNewChat();
      setState(() => _currentChatId = newChat.id);
    }
  }

  Future<DocumentReference> _createNewChat() async {
    final user = _user!;
    final chatsCol = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chats');

    final now = FieldValue.serverTimestamp();
    return await chatsCol.add({
      'title': 'New chat',
      'createdAt': now,
      'updatedAt': now,
      'lastMessage': null,
    });
  }

  Future<void> _startNewChat() async {
    final newChat = await _createNewChat();
    setState(() {
      _currentChatId = newChat.id;
      _controller.clear();
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_currentChatId == null || _user == null) return;

    final user = _user!;
    final chatDoc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .doc(_currentChatId!);

    final messageCollection = chatDoc.collection('messages');
    final currentText = _controller.text;
    _controller.clear();

    await messageCollection.add({
      'text': currentText,
      'sender': 'user',
      'timestamp': FieldValue.serverTimestamp(),
    });

    final newTitle = _makeTitleFrom(currentText);
    await chatDoc.set({
      'lastMessage': currentText,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final chatSnapshot = await chatDoc.get();
    if ((chatSnapshot.data()?['title'] as String? ?? 'New chat') ==
        'New chat') {
      await chatDoc.update({'title': newTitle});
    }

    _scrollToBottom();

    final typingDoc = await messageCollection.add({
      'text': 'Rufi is typing... ⏳',
      'sender': 'bot',
      'timestamp': FieldValue.serverTimestamp(),
      'isTyping': true,
    });

    try {
      final historySnapshot =
          await messageCollection.orderBy('timestamp', descending: true).limit(15).get();

      final historyDocs = historySnapshot.docs.reversed.toList();

      final history = <Content>[];
      for (final doc in historyDocs) {
        final data = doc.data();
        if (data['isTyping'] == true || doc.id == typingDoc.id) continue;
        final isUserMessage = data['sender'] == 'user';
        history.add(
          Content(isUserMessage ? 'user' : 'model', [TextPart(data['text'])]),
        );
      }

      final chat = _model.startChat(history: history);
      final response = await chat.sendMessage(Content.text(currentText));
      final botMessage = (response.text ?? "Sorry, I couldn't respond.").trim();

      await typingDoc.set({
        'text': botMessage,
        'sender': 'bot',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await chatDoc.update({
        'lastMessage': botMessage,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _scrollToBottom();
    } catch (e) {
      await typingDoc.set({
        'text':
            '⚠️ Sorry, I am having trouble connecting. Please try again later.',
        'sender': 'bot',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  String _makeTitleFrom(String text) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final words = cleaned.split(' ');
    final take = words.length > 6 ? words.sublist(0, 6) : words;
    final title = take.join(' ');
    return title.isEmpty
        ? 'New chat'
        : title[0].toUpperCase() + title.substring(1);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _deleteChat(String chatId) async {
    if (_user == null) return;
    final user = _user!;
    final chatRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .doc(chatId);

    final msgs = await chatRef.collection('messages').get();
    for (final d in msgs.docs) {
      await d.reference.delete();
    }
    await chatRef.delete();

    if (_currentChatId == chatId) {
      await _ensureSessionOnOpen();
      setState(() {});
    }
  }


  @override
  Widget build(BuildContext context) {
    // ... (Your existing build method with Scaffold, AppBar, etc.)
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    if (_user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in.")));
    }

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text(
          "Rufi",
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Chat History',
            icon: const Icon(Icons.history_edu_outlined, color: Colors.white),
            onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _ChatDrawer(
        currentChatId: _currentChatId,
        onSelect: (id) => setState(() => _currentChatId = id),
        onNewChat: _startNewChat,
        onDelete: _deleteChat,
      ),
      body: _currentChatId == null
          ? const Center(child: CupertinoActivityIndicator())
          : Column(
              children: [
                Expanded(
                  child: _MessagesView(
                    chatId: _currentChatId!,
                    scrollController: _scrollController,
                    emptyState: _EmptyState(onNewChat: _startNewChat),
                  ),
                ),
                _buildMessageInputArea(),
              ],
            ),
    );
  }

  Widget _buildMessageInputArea() {
    // ... (Your existing message input area widget)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: "Message Rufi...",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24.0),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                fixedSize: const Size(50, 50),
              ),
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

// --- All the other Widgets from your file go here ---
// ... (_ChatDrawer, _MessagesView, _EmptyState, _MessageBubble, 
//      _UserMessageBubble, _TypingIndicator)

class _ChatDrawer extends StatelessWidget {
  // ... (Your existing _ChatDrawer code)
  final String? currentChatId;
  final void Function(String id) onSelect;
  final VoidCallback onNewChat;
  final Future<void> Function(String id) onDelete;

  const _ChatDrawer({
    required this.currentChatId,
    required this.onSelect,
    required this.onNewChat,
    required this.onDelete,
  });

  void _showDeleteConfirmation(
    BuildContext context,
    String chatId,
    String chatTitle,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ConfirmationDialog(
          title: 'Delete Chat',
          content: 'Are you sure you want to Delete the chat?',
          confirmText: 'Delete',
          cancelText: 'Cancel',
          icon: Icons.delete_outline_rounded,
          cancelOnPressed: () {
            Navigator.of(dialogContext).pop();
          },
          confirmOnPressed: () async {
            Navigator.of(dialogContext).pop(); // Close the dialog
            await onDelete(chatId);
            showBottomToast('Chat deleted successfully');
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final chatsQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .orderBy('updatedAt', descending: true);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: Colors.black54,
              ),
              title: const Text('New Chat'),
              onTap: () {
                Navigator.pop(context);
                onNewChat();
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: chatsQuery.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No chats yet.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      final id = d.id;
                      final rawTitle = (d['title'] as String?)?.trim();
                      final title =
                          rawTitle == null || rawTitle.isEmpty ? 'New chat' : rawTitle;
                      final isActive = id == currentChatId;

                      return ListTile(
                        leading: const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.black54,
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          tooltip: 'Delete Chat',
                          onPressed: () {
                            _showDeleteConfirmation(context, id, title);
                          },
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(id);
                        },
                        selected: isActive,
                        selectedTileColor:
                            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesView extends StatelessWidget {
  // ... (Your existing _MessagesView code)
  final String chatId;
  final ScrollController scrollController;
  final Widget emptyState;

  const _MessagesView({
    required this.chatId,
    required this.scrollController,
    required this.emptyState,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final messageQuery = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false);

    return StreamBuilder<QuerySnapshot>(
      stream: messageQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CupertinoActivityIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return emptyState;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.jumpTo(scrollController.position.maxScrollExtent);
          }
        });

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final text = (data['text'] ?? '').toString();
            final sender = (data['sender'] ?? 'bot').toString();
            return _MessageBubble(text: text, isUser: sender == 'user');
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  // ... (Your existing _EmptyState code)
  final VoidCallback onNewChat;
  const _EmptyState({required this.onNewChat});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            'https://res.cloudinary.com/dui67nlwb/image/upload/v1756235987/unnamed-removebg-preview_1_thnonz.png',
            height: 250,
          ),
          const Text(
            "Hello, I'm Rufi",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your personal guide for career and education.\nHow can I assist you today? 🚀",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  // ... (Your existing _MessageBubble code)
  final String text;
  final bool isUser;

  const _MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    if (text.toLowerCase().contains('rufi is typing')) {
      return const _TypingIndicator();
    }
    if (isUser) {
      return _UserMessageBubble(text: text);
    }
    return _BotMessageResponse(text: text);
  }
}

class _UserMessageBubble extends StatelessWidget {
  // ... (Your existing _UserMessageBubble code)
  const _UserMessageBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userInitial = (user?.displayName ?? "U").isNotEmpty
        ? (user!.displayName!).substring(0, 1).toUpperCase()
        : "U";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Text(
              userInitial,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  // ... (Your existing _TypingIndicator code)
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          CircleAvatar(
            child: Image.network(
              'https://res.cloudinary.com/dui67nlwb/image/upload/v1756235987/unnamed-removebg-preview_1_thnonz.png',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFEFEFEF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const CupertinoActivityIndicator(),
          ),
        ],
      ),
    );
  }
}


// =========================================================================
// ✨ FINAL, COMBINED SOLUTION FOR MARKDOWN AND CODE RENDERING ✨
// =========================================================================

// You can now DELETE your old `_MarkdownBuilder` class completely.
// These three new classes handle everything.

// 1. The main response bubble
class _BotMessageResponse extends StatelessWidget {
  const _BotMessageResponse({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            child: Image.network(
              'https://res.cloudinary.com/dui67nlwb/image/upload/v1756235987/unnamed-removebg-preview_1_thnonz.png',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            // Replaced the manual parser with the more powerful MarkdownBody
            child: MarkdownBody(
              data: text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              // This tells MarkdownBody how to build code blocks using our custom widgets
              builders: {
                'code': CodeElementBuilder(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

// 2. The builder that intercepts code blocks from the Markdown parser
class CodeElementBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Extracts language from ```dart format
    final String language = element.attributes['class']?.replaceFirst('language-', '') ?? '';
    final String code = element.textContent;

    return CodeBlock(
      code: code,
      language: language,
    );
  }
}
 

class CodeBlock extends StatelessWidget {
  final String code;
  final String? language;

  const CodeBlock({
    Key? key,
    required this.code,
    this.language,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Header Row (Language + Copy button)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                if (language != null && language!.isNotEmpty)
                  Text(
                    language!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_all_outlined,
                      size: 20, color: Colors.grey),
                  tooltip: 'Copy Code',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.black54),

          // 🔹 Syntax Highlighted Code
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16.0),
            child: HighlightView(
              code,
              language: language ?? 'dart',
              theme: isDarkMode ? draculaTheme : githubTheme,
              padding: EdgeInsets.zero,
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
