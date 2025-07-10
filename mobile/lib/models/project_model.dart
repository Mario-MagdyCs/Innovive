import 'guide_model.dart';
import 'dart:convert';
import '../../models/instruction_material_model.dart';
import '../../models/instruction_step_model.dart';

class ProjectModel {
  String? id;
  String? userId;
  String? image;
  String generatedImageUrl;
  List<String> category;
  GuideModel? guide;

  ProjectModel({
    this.id,
    this.userId,
    required this.generatedImageUrl,
    this.image,
    required this.category,
    this.guide,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'],
      userId: json['user_id'],
      image: json['image'],
      generatedImageUrl: json['generatedImageUrl'],
      category: json['category'],
      guide: GuideModel.fromJson(json['guide']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'image': image,
      'generatedImageUrl': generatedImageUrl,
      'category': category,
      'guide': guide?.toMap(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'image': image,
      'category': category,
      'generatedImageUrl': generatedImageUrl,
      'name': guide?.toMap()["name"],
      'difficulty': guide?.toMap()["level"],
      'materials': guide?.toMap()["materials"],
      'instructions': guide?.toMap()["instructions"],
    };
  }

  factory ProjectModel.fromJsonDB(Map<String, dynamic> json) {
    final materialsJsonList = (json['materials'] as List<dynamic>);
    final instructionsJsonList = (json['instructions'] as List<dynamic>);

    final materials =
        materialsJsonList.map((item) {
          // If item is already Map, use it directly
          if (item is Map<String, dynamic>) {
            return InstructionMaterial.fromJson(item);
          }
          // If item is String, decode it
          final decoded = jsonDecode(item as String);
          return InstructionMaterial.fromJson(decoded);
        }).toList();

    final steps =
        instructionsJsonList.map((item) {
          if (item is Map<String, dynamic>) {
            return InstructionStep.fromJson(item);
          }
          final decoded = jsonDecode(item as String);
          return InstructionStep.fromJson(decoded);
        }).toList();

    return ProjectModel(
      id: json['id'],
      userId: json['user'],
      category:
          (json['category'] as List<dynamic>).map((e) => e as String).toList(),
      image: json['image'],
      generatedImageUrl: json['generatedImageUrl'],
      guide: GuideModel(
        name: json['name'],
        level: json['difficulty'],
        materials: materials,
        steps: steps,
      ),
    );
  }
}
