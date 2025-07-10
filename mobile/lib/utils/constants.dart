import 'package:flutter/material.dart';

/// 🌿 Common UI Colors
const Color kGreenColor = Color(0xFF4CAF50);
const Color kLightGrey = Color(0xFFF5F5F5);
const Color kDarkGrey = Color(0xFF616161);

/// 🧠 Dropdown Model Options
const List<String> modelOptions = ['Preserving Model', 'Creative Model'];

/// 🌐 Base IP of Flask server
const String baseIp = '192.168.1.105'; // ✅ Update to your local IP

/// 🌐 API Endpoints
const String classifyUrl = "http://$baseIp:5000/classify-base64";
const String promptUrl = "http://$baseIp:5003/generate-prompt";
const String instructionUrl = "http://$baseIp:5003/generate-instructions";
const String clarifyStepUrl = "http://$baseIp:5003/clarify-step";
const String generateImagePreservingUrl = "http://$baseIp:5006/generate-replicate-base64";
const String generateImageCreativeUrl = "http://$baseIp:5005/generate-replicate";
