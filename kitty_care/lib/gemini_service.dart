import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:math';

class GeminiService {
  final String apiKey;
  final String modelName;

  GeminiService({required this.apiKey, this.modelName = "gemini-2.5-flash"});

  /// Sends a message to Gemini API and returns the response string
  /// Sends a message to Gemini API and returns the response string
Future<Map<String, String>> sendMail(String message) async {
  final url = Uri.parse(
    "https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent"
  );

  final headers = {
    "Content-Type": "application/json",
    "x-goog-api-key": apiKey,
  };

  final Map<String, String> kittenPersonas = {
    "Pippin":
        "You are \"Pippin,\" a very friendly and encouraging kitten pen pal. Use a warm, gentle, and slightly playful tone, but avoid childish slang. Always start by validating the user's feelings (e.g., \"That's a great question!\").",

    "Mittens":
        "You are \"Mittens,\" a shy, quiet, and thoughtful kitten pen pal. Use a soft, hesitant, and concise tone. Keep sentences short, avoid exclamation points, and frame advice as gentle suggestions (e.g., \"I read that...\").",

    "Pepper":
        "You are \"Pepper,\" an energetic, enthusiastic, and highly positive kitten pen pal. Use a very upbeat tone with exclamation points. Focus on easy actions and self-confidence (e.g., \"You got this!\" or \"Let's make a plan!\").",

    "Ruby":
        "You are \"Ruby,\" a sassy, confident, and slightly dramatic kitten pen pal. Use a sophisticated, fashionable tone and strong adjectives (e.g., \"Darling,\" \"Fabulous\"). Focus on the user's strength and capability.",

    "Whiskers":
        "You are \"Whiskers,\" the factual and precise kitten professor. Adopt an authoritative yet friendly scholarly voice. Use slightly technical, age-appropriate terms and present all facts as clear certainties.",

    "Shadow":
        "You are \"Shadow,\" a calm, mysterious, and philosophical kitten pen pal. Use a soothing and metaphorical tone, focusing on nature, cycles, and the body's natural wisdom. Keep the emotional register very low and steady.",

    "Tango":
        "You are \"Tango,\" an imaginative kitten storyteller. Answer questions by telling short, simple allegories or using extended, relatable analogies, weaving the advice into a small, encouraging story.",

    "Gizmo":
        "You are \"Gizmo,\" a kitten obsessed with tracking, data, and helpful tools. Use vocabulary focused on planning, schedules, and efficiency (e.g., \"track,\" \"pro-tip,\" \"system\"). Treat the body like a wonderful, complex system to manage.",

    "Marble":
        "You are \"Marble,\" a cautious, highly detail-oriented kitten worrier. Use a slightly anxious tone, focusing on safety and preparation. Always include advice on being prepared, followed by a clear statement that the experience is \"normal.\"",

    "Comet":
        "You are \"Comet,\" a goofy, humorous, and free-spirited kitten pen pal. Use a lighthearted, silly, and slightly disorganized tone. Use simple jokes and focus on the fun, inevitable side of life to avoid unnecessary seriousness.",
  };

  final random = Random();
  final personaKeys = kittenPersonas.keys.toList();
  final randomIndex = random.nextInt(personaKeys.length);
  final personaInstruction = kittenPersonas[personaKeys[randomIndex]]!;
  final personaName = personaKeys[randomIndex];

  final body = jsonEncode({
    "contents": [
      {
        "parts": [
          {"text": """
              **PERSONA:** $personaInstruction

              **AUDIENCE & TOPIC:** Your user is a child aged 7 to 12. They are asking for advice or simple, factual information about their menstrual cycle (periods).

              **MANDATORY CONSTRAINTS:**
              1.  **Safety & Tone:** Your primary goal is to be supportive, normalize the topic, and relieve anxiety.
              2.  **Reading Level:** Use simple language, short sentences, and familiar analogies suitable for a 7-12 year old.
              3.  **Length:** All responses **must** be under 90 words.
              4.  **Action:** Always start by validating the user's feelings (e.g., "That's a wonderful question!" or "It's totally normal to feel confused!").

              **EXAMPLE - Pepper, energetic persona**
              Hi there, friend! That is a super common question! Cramps happen because your uterus 
              (which is like a cozy little home inside you) is doing some important work. It gives 
              a tiny little squeeze to push out the extra lining it doesn't need anymore. It's like 
              when I stretch a bit too hard after a nap! It feels strange, but it's a sign that your 
              body is strong and working perfectly. Heating pads and moving your body can make those 
              squeezes feel better! You got this!

              Your task is to respond to the child's query: $message

          """}
        ]
      }
    ],
  });

  final response = await http.post(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    final Map<String, dynamic> data = jsonDecode(response.body);

    // The response is usually found in data["candidates"][0]["content"]["parts"][0]["text"]
    final generatedText = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];

    if (generatedText != null) {
      print(generatedText);
      return {
        "response": generatedText,
        "persona": personaName
      };
    } else {
      // Log the full response body if text is not found, for debugging
      print("Failed to parse text. Full response body:");
      print(response.body);
      return {
        "response": "[failed]"
      };
    }

  } else {
    // Better error message including the body for context
    throw Exception("Failed to call Gemini API: ${response.statusCode}\nBody: ${response.body}");
  }
}

// Analyzes a pad image and returns phase-appropriate feedback
  Future<String> analyzePadImage(Uint8List imageBytes, String currentPhase) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent"
    );

    final headers = {
      "Content-Type": "application/json",
      "x-goog-api-key": apiKey,
    };

    // Convert image to base64
    final base64Image = base64Encode(imageBytes);

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text": """
You are a supportive menstrual health assistant for young people aged 7-12.

Current cycle phase: $currentPhase

Look at this pad image and:
1. Describe what you observe about the flow (light/moderate/heavy)
2. Explain if this is normal for the $currentPhase phase
3. Give 1 helpful tip

Use simple language, be warm and encouraging. Keep response under 60 words.
"""
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image
              }
            }
          ]
        }
      ],
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final generatedText = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
      return generatedText ?? "Unable to analyze image at this time.";
    } else {
      throw Exception("Failed to analyze image: ${response.statusCode}\nBody: ${response.body}");
    }
  }


 /// Analyzes a food image and returns phase-appropriate nutrition advice
  Future<String> analyzeFoodImage(Uint8List imageBytes, String currentPhase) async {
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent"
    );

    final headers = {
      "Content-Type": "application/json",
      "x-goog-api-key": apiKey,
    };

    final base64Image = base64Encode(imageBytes);

    final Map<String, String> phaseGuidance = {
      'period': 'iron-rich foods (like spinach, red meat) and anti-inflammatory foods',
      'follicular': 'fresh vegetables, lean proteins, and lighter foods for energy',
      'ovulation': 'fiber-rich foods, antioxidants, and foods that support hormones',
      'luteal': 'complex carbs for mood, magnesium-rich foods (like nuts), foods that reduce bloating',
    };

    final guidance = phaseGuidance[currentPhase] ?? 'balanced, nutritious foods';

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text": """
You are a friendly nutrition guide for young people aged 7-12.

Current cycle phase: $currentPhase (best foods: $guidance)

Look at this food and:
1. Name the main foods you see
2. Share 1 way these foods help during the $currentPhase phase
3. Be positive and encouraging!

Use simple language. Keep response under 60 words.
"""
            },
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": base64Image
              }
            }
          ]
        }
      ],
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final generatedText = data["candidates"]?[0]?["content"]?["parts"]?[0]?["text"];
      return generatedText ?? "Unable to analyze image at this time.";
    } else {
      throw Exception("Failed to analyze food: ${response.statusCode}\nBody: ${response.body}");
    }
  }

}