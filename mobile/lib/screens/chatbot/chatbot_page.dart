import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile/services/rag_service.dart';
import 'package:mobile/services/translation_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../provider/project_provider.dart';
import '../../services/api_service.dart';
import '../../services/speech_service.dart';
import '../../models/message_model.dart';
import '../../models/project_model.dart';
import '../../models/instruction_step_model.dart';
import 'chat_input_bar.dart';
import 'chat_message_bubble.dart';
import 'dropdowns_selector.dart';

class ChatbotPage extends ConsumerStatefulWidget {
  const ChatbotPage({super.key});

  @override
  ConsumerState<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends ConsumerState<ChatbotPage> {
  final List<MessageModel> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final SpeechService _speechService = SpeechService();

  final userId = Supabase.instance.client.auth.currentUser?.id;

  String _selectedLanguage = 'en'; // Default English
  String _lastStableText = ''; // save text before starting speech

  final Map<String, String> languageMap = {
    'English': 'en',
    'Arabic': 'ar',
    'French': 'fr',
    'German': 'de',
    'Spanish': 'es',
  };

  String _selectedModel = 'Preserving Model';
  bool _isListening = false;
  bool _isBotThinking = false;
  bool _awaitingClarification = false;
  bool _awaitingSteps = false;
  File? _pendingImage;

  String? classifyImage;

  ProjectModel? _pendingProject;

  @override
  void initState() {
    super.initState();
    _speechService.init(
      onStatus: (status) {
        if (status == 'done') _stopListening();
      },
      onError: (error) => debugPrint("Speech Error: $error"),
    );
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _lastStableText = _controller.text; // save current input
    });

    await _speechService.startListening((recognizedText) {
      setState(() {
        _controller.text = ('$_lastStableText $recognizedText').trim();
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      });
    });
  }

  void _stopListening() {
    _speechService.stopListening();
    setState(() => _isListening = false);
  }

  int? extractStepNumber(String text, Map<String, int> localizedNumbers) {
    final RegExp regex = RegExp(r'(?:step\s*)?(\d+|\w+)', caseSensitive: false);
    final matches = regex.allMatches(text.toLowerCase());

    for (var match in matches) {
      final captured = match.group(1);
      if (captured == null) continue;

      final word = captured.toLowerCase();

      // Try direct digit first
      final digit = int.tryParse(word);
      if (digit != null) return digit;

      // Try mapping word to number
      if (localizedNumbers.containsKey(word)) {
        return localizedNumbers[word];
      }
    }

    return null; // No valid step number found
  }

  void _sendMessageFromInput() async {
    String text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(MessageModel(isUser: true, text: text));
      _controller.clear();
      _isBotThinking = true;
      _messages.add(MessageModel(isUser: false, isLoading: true));
    });

    try {
      if (_selectedLanguage != 'en') {
        text = await TranslationService.translateText(text, _selectedLanguage);
        print("Translated text: $text"); // helpful for debugging
      }
    } catch (e) {
      setState(() {
        _isBotThinking = false;
        _messages.removeLast();
        _messages.add(
          MessageModel(
            isUser: false,
            text: "❌ Failed to translate: ${e.toString()}",
          ),
        );
      });
      return;
    }

    /// --- Existing logic continues here ---
    final Map<String, List<String>> yesIntents = {
      'en': ['yes', 'sure', 'ok', 'continue', 'go ahead'],
      'ar': ['نعم', 'تمام', 'اكمل', 'استمر'],
      'fr': ['oui', 'daccord', 'continue', 'vas-y'],
      'es': ['sí', 'vale', 'continuar'],
      'de': ['ja', 'weiter', 'fortfahren'],
    };

    if (_awaitingSteps == true) {
      final currentYesWords = yesIntents[_selectedLanguage] ?? ['yes'];
      final loweredText = text.toLowerCase();

      // Check if user text contains any of the intent keywords
      final isYesIntent = currentYesWords.any(
        (word) => loweredText.contains(word),
      );

      if (isYesIntent) {
        await _handleInstructionsRequest();
        return;
      }
    }

    if (_awaitingClarification && _pendingProject?.guide!.steps != null) {
      final Map<String, List<String>> clarifyIntents = {
        'en': ['clarify', 'explain', 'detail'],
        'ar': ['وضح', 'اشرح', 'فسر'],
        'fr': ['clarifier', 'expliquer'],
        'de': ['erklären', 'klarstellen'],
        'es': ['aclarar', 'explicar'],
      };

      final Map<String, Map<String, int>> numberWordsMap = {
        'en': {
          'one': 1,
          'two': 2,
          'three': 3,
          'four': 4,
          'five': 5,
          'six': 6,
          'seven': 7,
          'eight': 8,
          'nine': 9,
        },
        'ar': {
          'واحد': 1,
          'اثنان': 2,
          'ثلاثة': 3,
          'أربعة': 4,
          'خمسة': 5,
          'ستة': 6,
          'سبعة': 7,
          'ثمانية': 8,
          'تسعة': 9,
        },
        'fr': {
          'un': 1,
          'deux': 2,
          'trois': 3,
          'quatre': 4,
          'cinq': 5,
          'six': 6,
          'sept': 7,
          'huit': 8,
          'neuf': 9,
        },
        'de': {
          'eins': 1,
          'zwei': 2,
          'drei': 3,
          'vier': 4,
          'fünf': 5,
          'sechs': 6,
          'sieben': 7,
          'acht': 8,
          'neun': 9,
        },
        'es': {
          'uno': 1,
          'dos': 2,
          'tres': 3,
          'cuatro': 4,
          'cinco': 5,
          'seis': 6,
          'siete': 7,
          'ocho': 8,
          'nueve': 9,
        },
      };

      final clarifyKeywords = clarifyIntents[_selectedLanguage] ?? ['clarify'];
      final localizedNumbers =
          numberWordsMap[_selectedLanguage] ?? numberWordsMap['en']!;
      final loweredText = text.toLowerCase();

      bool clarifyDetected = clarifyKeywords.any(
        (word) => loweredText.contains(word),
      );

      // ✅ If clarification intent detected
      if (clarifyDetected) {
        // extract any possible number
        final RegExp regex = RegExp(
          r'(?:step\s*)?(\d+|\w+)',
          caseSensitive: false,
        );
        final match = regex.firstMatch(text);
        int? stepNumber;

        if (match != null) {
          // final captured = match.group(1)!.toLowerCase();
          stepNumber = extractStepNumber(text, localizedNumbers);
        }

        final List<InstructionStep> steps = _pendingProject!.guide!.steps;
        final String projectName = _pendingProject!.guide!.name;

        if (stepNumber! >= 1 && stepNumber <= steps.length) {
          final InstructionStep step = steps[stepNumber - 1];
          await _getStepClarification(
            projectName,
            stepNumber,
            step.title,
            step.description,
          );
          return;
        } else {
          setState(() {
            _isBotThinking = false;
            _messages.removeLast();
            _messages.add(
              MessageModel(
                isUser: false,
                text:
                    "❌ Invalid step number. This project has ${steps.length} steps.",
              ),
            );
          });
          return;
        }
      }
    }

    // ✅ After translation step:
    try {
      final ragReply = await RagService.queryWithKnowledge(text);

      if (ragReply == '[IRRELEVANT]') {
        setState(() {
          _isBotThinking = false;
          _messages.removeLast();
          _messages.add(
            MessageModel(
              isUser: false,
              text:
                  "❗ Sorry, this question is not related to Innovive platform.",
            ),
          );
        });
        return;
      }

      if (ragReply.isNotEmpty) {
        setState(() {
          _isBotThinking = false;
          _messages.removeLast();
          _messages.add(MessageModel(isUser: false, text: ragReply));
        });
        return;
      }
    } catch (e) {
      print("RAG failed: $e");
    }

    // Default fallback (only reached if no intents matched)
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isBotThinking = false;
      _messages.removeLast();
      _messages.add(MessageModel(isUser: false, text: 'Echo: $text'));
    });
  }

  Future<void> _sendImageWithCaption() async {
    String text = _captionController.text.trim();
    if (_pendingImage == null) return;

    // ✅ Handle translation of the caption (if language is not English)
    try {
      if (_selectedLanguage != 'en' && text.isNotEmpty) {
        text = await TranslationService.translateText(text, _selectedLanguage);
        print("Translated caption: $text");
      }
    } catch (e) {
      setState(() {
        _isBotThinking = false;
        _messages.removeLast();
        _messages.add(
          MessageModel(
            isUser: false,
            text: "❌ Failed to translate caption: ${e.toString()}",
          ),
        );
      });
      return;
    }

    final imageToSend = _pendingImage; // store reference before clearing

    setState(() {
      _messages.add(
        MessageModel(
          isUser: true,
          text: text.isNotEmpty ? text : "Generate something with this.",
          image: imageToSend,
        ),
      );
      _isBotThinking = true;
      _messages.add(MessageModel(isUser: false, isLoading: true));
      _captionController.clear();
      _pendingImage = null;
    });

    await _sendImage(imageToSend!);
  }

  Future<void> _handleInstructionsRequest() async {
    if (_pendingProject == null) return;

    String base64ToSend;

    base64ToSend = await ApiService.downloadImageAndConvertToBase64(
      _pendingProject!.generatedImageUrl,
    );

    final result = await ApiService.generateInstructions(base64ToSend);

    // final result = await ApiService.generateInstructions(
    //   _pendingProject!.generatedImage,
    // );

    setState(() {
      _isBotThinking = false;
      _messages.removeLast();
      _messages.add(
        MessageModel(
          isUser: false,
          type: 'instructions',
          data: result, // assuming GuideModel used
        ),
      );

      _pendingProject!.guide = result;
      _pendingProject!.image = base64ToSend;

      if (_pendingProject != null) {
        ref
            .read(projectControllerProvider.notifier)
            .saveProject(_pendingProject!);
      }

      _awaitingSteps = false;
      _awaitingClarification = true;
    });
  }

  Future<void> _getStepClarification(
    String projectName,
    int stepNumber,
    String title,
    String description,
  ) async {
    try {
      final clarification = await ApiService.clarifyStep(
        projectName,
        stepNumber,
        title,
        description,
      );

      final translatedClarification = await TranslationService.translateText(
        clarification,
        _selectedLanguage,
      );
      setState(() {
        _isBotThinking = false;
        _messages.removeLast();
        _messages.add(
          MessageModel(
            isUser: false,
            type: 'clarification',
            data: {'step': stepNumber, 'content': translatedClarification},
          ),
        );
      });
    } catch (e) {
      setState(() {
        _isBotThinking = false;
        _messages.removeLast();
        _messages.add(
          MessageModel(
            isUser: false,
            text: "❌ Failed to clarify step. Please try again.",
          ),
        );
      });
    }
  }

  Future<void> _sendImage(File image) async {
    final base64 = await ApiService.convertFileToBase64(image);
    final category = await ApiService.classifyImage(base64);
    final prompt = await ApiService.generatePrompt(category, base64);
    final generatedURL = await ApiService.generateImage(
      prompt,
      base64,
      _selectedModel == 'Preserving Model',
    );

    final Map<String, String> projectGeneratedTranslations = {
      'en': 'Project generated using',
      'ar': 'تم إنشاء المشروع باستخدام',
      'fr': 'Projet généré en utilisant',
      'es': 'Proyecto generado usando',
      'de': 'Projekt erstellt mit',
    };

    final Map<String, String> askStepsTranslations = {
      'en': 'Would you like to see the steps?',
      'ar': 'هل تود رؤية الخطوات؟',
      'fr': 'Voulez-vous voir les étapes ?',
      'es': '¿Quieres ver los pasos?',
      'de': 'Möchten Sie die Schritte sehen?',
    };

    setState(() {
      _isBotThinking = false;
      _messages.removeLast();

      final generatedText =
          projectGeneratedTranslations[_selectedLanguage] ??
          'Project generated using';
      final questionText =
          askStepsTranslations[_selectedLanguage] ??
          'Would you like to see the steps?';

      _messages.add(
        MessageModel(
          isUser: false,
          text: "🛠️ $generatedText ${category.join(', ')}.\n$questionText",
          networkImage: generatedURL,
        ),
      );

      print("🟢🟢🟢🟢🟢🟢 THIS IS USER ID ${userId}");
      _pendingProject = ProjectModel(
        userId: userId,
        category: category,
        generatedImageUrl: generatedURL,
      );
    });

    _awaitingSteps = true;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked != null) {
      setState(() {
        _pendingImage = File(picked.path);
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Picked file: ${result.files.first.name}')),
      );
    }
  }

  void showAttachmentOptions() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final iconColor = isDarkMode ? Colors.white : Colors.black54;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.insert_drive_file, color: iconColor),
              title: Text("Files", style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: iconColor),
              title: Text("Camera", style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo, color: iconColor),
              title: Text("Photos", style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return ChatMessageBubble(
          message: _messages[index],
          selectedLanguage: _selectedLanguage,
          translateText: TranslationService.translateText,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF333333);

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        elevation: 0,
        title: DropdownsSelector(
          selectedModel: _selectedModel,
          onChanged: (model) => setState(() => _selectedModel = model),
          selectedLanguage: _selectedLanguage,
          onLanguageChanged: (lang) => setState(() => _selectedLanguage = lang),
          languageMap: languageMap,
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          ChatInputBar(
            controller:
                _pendingImage != null ? _captionController : _controller,
            onSendPressed:
                _pendingImage != null
                    ? _sendImageWithCaption
                    : _sendMessageFromInput,
            onAttachPressed: showAttachmentOptions,
            isListening: _isListening,
            onMicToggle: () {
              if (_isListening) {
                _stopListening();
              } else {
                _startListening();
              }
            },
            pendingImage: _pendingImage,
            onRemoveImage: () {
              setState(() {
                _pendingImage = null;
                _captionController.clear();
              });
            },
          ),
        ],
      ),
    );
  }
}
