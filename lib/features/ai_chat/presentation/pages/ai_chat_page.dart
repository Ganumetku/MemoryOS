import 'package:flutter/material.dart';

class AiChatPage extends StatelessWidget {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mockMessages = [
      {
        'sender': 'ai',
        'text':
            'Hello! I am your MemoryOS assistant. I have compiled and organized all your captured experiences. You can ask me to recall, summarize, or analyze past events!',
        'time': '2:30 PM',
      },
      {
        'sender': 'user',
        'text': 'What details do we have about our new project?',
        'time': '2:31 PM',
      },
      {
        'sender': 'ai',
        'text':
            'We initialized MemoryOS today, setting up Clean Architecture + Feature-First modules. You noted it uses BLoC for states and GoRouter for pages.',
        'time': '2:31 PM',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
            SizedBox(width: 8),
            Text('Memory AI'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: mockMessages.length,
                itemBuilder: (context, index) {
                  final msg = mockMessages[index];
                  final isAi = msg['sender'] == 'ai';
                  return Align(
                    alignment: isAi
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isAi
                            ? theme.colorScheme.surface
                            : theme.colorScheme.primary,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isAi ? 0 : 16),
                          bottomRight: Radius.circular(isAi ? 16 : 0),
                        ),
                        border: isAi
                            ? Border.all(
                                color: theme.colorScheme.outline.withAlpha(30),
                              )
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['text']!,
                            style: TextStyle(
                              color: isAi
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onPrimary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Text(
                              msg['time']!,
                              style: TextStyle(
                                fontSize: 10,
                                color: isAi ? Colors.grey : Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Message input field
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withAlpha(20),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Ask about your memories...',
                        fillColor: theme.scaffoldBackgroundColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {},
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
