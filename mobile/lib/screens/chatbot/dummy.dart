import 'dart:io';
  import 'package:flutter/material.dart';
  import 'package:image_picker/image_picker.dart';
  import 'package:file_picker/file_picker.dart';
  import 'package:dropdown_button2/dropdown_button2.dart';
  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'package:speech_to_text/speech_to_text.dart' as stt;


class AnimatedDot extends StatefulWidget {
  final int index;
  const AnimatedDot({super.key, required this.index});

  @override
  State<AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<AnimatedDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) {
        return Opacity(
          opacity: (1 - ((widget.index * 0.3 + _controller.value) % 1)).clamp(0.3, 1.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}



  class ChatbotPage extends StatefulWidget {
    const ChatbotPage({super.key});

    @override
    State<ChatbotPage> createState() => _ChatbotPageState();
  }

  class _ChatbotPageState extends State<ChatbotPage> {
    final List<Map<String, dynamic>> _messages = [];
    final TextEditingController _controller = TextEditingController();
    final TextEditingController _imageCaptionController = TextEditingController();
    final ScrollController _scrollController = ScrollController();
    bool _waitingForStepClarification = false;
    File? _pendingImage;
    final Color greenColor = const Color(0xFF4CAF50);  // A nicer Material green shade
    bool _isBotThinking = false; // Added for loading state
    Map<String, dynamic>? _pendingProject;
    bool _waitingForSteps = false; // Added for steps state 
    late stt.SpeechToText _speech;
    bool _isListening = false;
    final String _voiceInput = '';
    final String _userEditedPrefix = '';
    String _lastStableText = '';



    // Add this method to close keyboard
    void _closeKeyboard() {
      FocusScope.of(context).unfocus();
    }



    Future<String> convertFileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }

void _startListening() async {
  _closeKeyboard();
  
  setState(() {
    _isListening = true;
    _lastStableText = _controller.text; // Save current text as stable
  });

  bool available = await _speech.initialize(
    onStatus: (val) {
      if (val == 'done') _stopListening();
    },
    onError: (val) => print('❌ Speech error: $val'),
  );

  if (available) {
    _speech.listen(
      onResult: (val) {
        // Only update if we're still listening
        if (_isListening) {
          setState(() {
            _controller.text = '$_lastStableText ${val.recognizedWords}'.trim();
            _moveCursorToEnd();
          });
        }
      },
      listenFor: Duration(minutes: 1),
    );
  }
}

void _stopListening() {
  if (_speech.isListening) _speech.stop();
  
  setState(() {
    _isListening = false;
    _lastStableText = _controller.text; // Update stable text
  });
}

void _moveCursorToEnd() {
  _controller.selection = TextSelection.fromPosition(
    TextPosition(offset: _controller.text.length),
  );
}

@override
void initState() {
  super.initState();
  _speech = stt.SpeechToText();
  
  _controller.addListener(() {
    // If not listening, update the stable text
    if (!_isListening) {
      _lastStableText = _controller.text;
    }
  });
}
  

 Future<void> generateProjectFromImage(File imageFile) async {
  setState(() {
    _isBotThinking = true;
    _messages.add({'isUser': false, 'isLoading': true});
  });

  try {
    final base64Image = await convertFileToBase64(imageFile);
    const String baseIp = "192.168.1.105";

    // 1. CLASSIFY
    final classifyRes = await http.post(
      Uri.parse("http://$baseIp:5000/classify-base64"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"image": base64Image}),
    );

    final classifyResult = jsonDecode(classifyRes.body);
    final List<String> materials = List<String>.from(classifyResult['results'] ?? []);
    final materialStr = materials.join(', ');

    // 2. PROMPT GENERATION
    final promptRes = await http.post(
      Uri.parse("http://$baseIp:5003/generate-prompt"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "materials": materials,
        "base64_image": base64Image,
      }),
    );

    final prompt = jsonDecode(promptRes.body)['prompt'];

    // 3. IMAGE GENERATION (Both use JSON now)
    final selectedPort = _selectedModel == 'Preserving Model' ? '5006' : '5005';

    final replicateRes = await http.post(
      Uri.parse("http://$baseIp:$selectedPort/generate-replicate${_selectedModel == 'Preserving Model' ? '-base64' : ''}"),
      headers: {
        'Content-Type': 'application/json',
        'X-Client-Type': 'mobile',
      },
      body: jsonEncode({
        "prompt": prompt,
        "image": base64Image,
      }),
    );

    if (replicateRes.statusCode == 200) {
      final result = jsonDecode(replicateRes.body);
      final imageUrl = result['url'];

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception("Flask did not return a valid image URL.");
      }

      print("🖼️ Image URL received: $imageUrl");

      setState(() {
        _isBotThinking = false;
        _messages.removeLast();

        _pendingProject = {
          'base64Image': base64Image,
          'materials': materials,
        };
        _waitingForSteps = true;

        _messages.add({
          'isUser': false,
          'networkImage': imageUrl,
          'text':
              "🛠️ Project generated using $materialStr.\n📦 Would you like to see the steps for this project? (yes/no)",
        });
      });
    } else {
      throw Exception("❌ Image generation failed: ${replicateRes.body}");
    }
  } catch (e) {
    setState(() {
      _isBotThinking = false;
      _messages.removeLast();
      _messages.add({
        'isUser': false,
        'text': "❌ Failed to generate project: ${e.toString()}",
      });
    });
  }
}




  Future<void> _generateInstructions(String base64Image) async {
    try {
      const String baseIp = "192.168.1.105";

      final response = await http.post(
        Uri.parse("http://$baseIp:5003/generate-instructions"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"image": base64Image}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String name = data['name'];
        final String level = data['level'];
        final List<dynamic> materials = data['materials'];
        final List<dynamic> instructions = data['instructions'];
        

        // Improved formatting with proper markdown
        String steps = "## $name\n";
        steps += "**Difficulty:** $level\n\n";
        
        steps += "### Materials\n";
        for (var m in materials) {
          steps += "- ${m['title']}: ${m['description']}\n";
        }

        steps += "\n### Steps\n";
        for (int i = 0; i < instructions.length; i++) {
          steps += "${i + 1}. ${instructions[i]['title']}\n   ${instructions[i]['description']}\n\n";
        }

        setState(() {
    _isBotThinking = false;
    _messages.removeLast(); // remove loading

    _messages.add({
      'isUser': false,
      'type': 'instructions', // 👈 flag this as a structured instruction message
      'data': {
        'name': name,
        'level': level,
        'materials': materials,
        'instructions': instructions,
      },
    });
      _pendingProject!['instructions'] = instructions;
    _pendingProject!['name'] = name;
    _waitingForStepClarification = true;
  });
      } else {
        throw Exception(data["error"] ?? "Instruction generation failed");
      }
    } catch (e) {
      setState(() {
        _isBotThinking = false;
        _messages.removeLast();
        _messages.add({'isUser': false, 'text': "❌ Failed to get instructions: ${e.toString()}"});
      });
    }
  }






    // Added loading bubble widget
    Widget _buildLoadingBubble() {
  return SizedBox(
    height: 24,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedDot(index: index);
      }),
    ),
  );
}

void _sendMessageFromInput() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _closeKeyboard();

    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _controller.clear();
      _isBotThinking = true;
      _messages.add({'isUser': false, 'isLoading': true});
    });

    // ✅ Handle step request
    if (_waitingForSteps && text.toLowerCase().contains("yes")) {
      final base64 = _pendingProject?['base64Image'];
      if (base64 != null) {
        _waitingForSteps = false;
        _generateInstructions(base64);
        return; // ✅ THIS prevents fallback from triggering
      }
    }
    // 🔍 STEP CLARIFICATION
  if (_waitingForStepClarification && _pendingProject?['instructions'] != null) {
    final RegExp regex = RegExp(r'(?:step|clarify)?\s*(\d+|one|two|three|four|five|six|seven|eight|nine)', caseSensitive: false);
    final match = regex.firstMatch(text);

    if (match != null) {
      int? stepNumber;

      final group = match.group(1)!.toLowerCase();
      const numberWords = {
        'one': 1,
        'two': 2,
        'three': 3,
        'four': 4,
        'five': 5,
        'six': 6,
        'seven': 7,
        'eight': 8,
        'nine': 9,
      };

      // Convert word or digit to int
      stepNumber = int.tryParse(group) ?? numberWords[group];

      final steps = _pendingProject!['instructions'];
      final name = _pendingProject!['name'];

      if (stepNumber != null && stepNumber >= 1 && stepNumber <= steps.length) {
        final step = steps[stepNumber - 1];
        _getStepClarification(name, stepNumber, step['title'], step['description']);
        return;
      } else {
        setState(() {
          _isBotThinking = false;
          _messages.removeLast();
          _messages.add({
            'isUser': false,
            'text': "❌ Invalid step number. This project has ${steps.length} steps.",
          });
        });
        return;
      }
    }
  }


    // ❌ This should not run if you're showing steps
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isBotThinking = false;
        _messages.removeLast();
        _messages.add({'text': 'Received: $text', 'isUser': false});
      });
    });
  }


  Future<void> _getStepClarification(
    String projectName,
    int stepNumber,
    String title,
    String description,
  ) async {
    const String baseIp = "192.168.1.105";

    try {
      final res = await http.post(
        Uri.parse("http://$baseIp:5003/clarify-step"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "project_name": projectName,
          "step_number": stepNumber,
          "step_title": title,
          "step_description": description,
        }),
      );

      final body = jsonDecode(res.body);

      final reply = body['text'] ??
          "🔍 Step $stepNumber: $title\n$description";

      setState(() {
        _isBotThinking = false;
        _messages.removeLast();
      _messages.add({
    'isUser': false,
    'type': 'clarification',
    'data': {
      'step': stepNumber,
      'content': reply,
    }
  });
      });
    } catch (e) {
      setState(() {
        _isBotThinking = false;
        _messages.removeLast();
        _messages.add({
          'isUser': false,
          'text': "❌ Failed to clarify step: ${e.toString()}",
        });
      });
    }
  }

    void _sendImageWithCaption() {
      if (_pendingImage == null) return;

    final caption = _imageCaptionController.text.trim();
    final imageToSend = _pendingImage!;
    _closeKeyboard();

    setState(() {
      _messages.add({
        'isUser': true,
        'image': imageToSend,
        'text': caption.isEmpty ? "Generate something with this." : caption,
      });
      _pendingImage = null;
      _imageCaptionController.clear();
    });

    generateProjectFromImage(imageToSend);
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
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text("Files"),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Photos"),
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

  Widget _buildMessage(Map<String, dynamic> msg) {
    final bool isUser = msg['isUser'];
    final bool isImage = msg['image'] != null;
    final bool isNetworkImage = msg['networkImage'] != null;
    final bool isLoading = msg['isLoading'] ?? false;
    final String time = "10:30 AM"; // Optional: replace with actual timestamp
    final double maxMessageWidth = MediaQuery.of(context).size.width * 0.75;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF4CAF50),
              child: Icon(Icons.eco, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxMessageWidth),
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 2),
                    child: Text(
                      "Innovive Assistant",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),

                // 🟩 Local image
                if (isImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      msg['image'],
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // 🟦 Network image (from Flask)
                if (isNetworkImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      msg['networkImage'],
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // 💬 Message bubble
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isUser ? greenColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
        child: isLoading
    ? _buildLoadingBubble()
    : msg['type'] == 'instructions'
        ? buildInstructions(msg['data'])
        : msg['type'] == 'clarification'
            ? buildStepClarification(msg['data']['step'], msg['data']['content'])
            : Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg['text'] ?? "",
                    style: TextStyle(
                      fontSize: 15,
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 10,
                      color: isUser ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),

                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Icon(Icons.done_all, size: 14, color: Colors.grey.shade400),
          ],
        ],
      ),
    );
  }
  Widget buildInstructions(Map<String, dynamic> data) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            data['name'],
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 8),
          
          // Difficulty
          Row(
    children: [
      Text(
        'Difficulty: ',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      Text(
        data['level'],
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: data['level'].toLowerCase().trim().replaceAll('.', '') == 'beginner'
      ? Colors.green
      : data['level'].toLowerCase().trim().replaceAll('.', '') == 'intermediate'
          ? Colors.orange
          : Colors.red,      
        ),
      ),
    ],
  ),
          Divider(height: 24, thickness: 1),
          
          // Materials
          Text(
            'Materials:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          ...data['materials'].map<Widget>((m) => Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: '${m['title']}: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: m['description']),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
          
          Divider(height: 24, thickness: 1),
          
          // Steps
          Text(
            'Steps:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          ...data['instructions'].asMap().entries.map<Widget>((entry) {
            int idx = entry.key + 1;
            var step = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    alignment: Alignment.topCenter,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.green,
                      child: Text(
                        '$idx',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          step['description'],
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }


  Widget buildStepClarification(int stepNumber, String content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.search, color: Colors.blue, size: 20),
              const SizedBox(width: 6),
              Text(
                'Step $stepNumber clarified',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }



    Widget buildInputBar() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_pendingImage != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _pendingImage!,
                          width: 70,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _pendingImage = null;
                              _imageCaptionController.clear();
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(3),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: Colors.grey.shade600),
                  onPressed: showAttachmentOptions,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pendingImage != null 
                                ? _imageCaptionController 
                                : _controller,
                            decoration: const InputDecoration(
                              hintText: 'Message...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            maxLines: 5,
                            minLines: 1,
                          ),
                        ),
                        IconButton(
  icon: Icon(
    _isListening ? Icons.mic : Icons.mic_none,
    color: _isListening ? greenColor : Colors.grey.shade600,
  ),
  onPressed: () {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  },
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(),
),

                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: greenColor,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _pendingImage != null
                        ? _sendImageWithCaption
                        : _sendMessageFromInput,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  String _selectedModel = 'Preserving Model'; // Default value
  final List<String> _modelOptions = ['Preserving Model', 'Creative Model'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    toolbarHeight: 60,
    titleSpacing: 0,
    title: Row(
    children: [
      const SizedBox(width: 8),
      CircleAvatar(
        radius: 18,
        backgroundColor: greenColor,
        child: const Icon(Icons.eco, size: 20, color: Colors.white),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Innovive Assistant",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              value: _selectedModel,
              onChanged: (value) {
                setState(() {
                  _selectedModel = value!;
                });
              },
              items: _modelOptions
                  .map((model) => DropdownMenuItem<String>(
                        value: model,
                        child: Text(
                          model,
                          style: TextStyle(
                            fontSize: 13,
                            color: greenColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
              buttonStyleData: const ButtonStyleData(
                height: 28,
                padding: EdgeInsets.symmetric(horizontal: 2),
              ),
              dropdownStyleData: DropdownStyleData(
                maxHeight: 120,
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              iconStyleData: IconStyleData(
                icon: Icon(Icons.arrow_drop_down, color: greenColor),
                iconSize: 18,
              ),
            ),
          ),
        ],
      ),
    ],
  ),
    actions: [
      IconButton(
        icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
        onPressed: () {},
      ),
    ],
  ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: false,
              padding: const EdgeInsets.only(top: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          buildInputBar(),
        ],
      ),
    );
  }
  }

