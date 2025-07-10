import '../../models/instruction_material_model.dart';
import '../../models/instruction_step_model.dart';

class GuideModel {
  final String name;
  final String level;
  final List<InstructionMaterial> materials;
  final List<InstructionStep> steps;

  GuideModel({
    required this.name,
    required this.level,
    required this.materials,
    required this.steps,
  });

  factory GuideModel.fromJson(Map<String, dynamic> json) {
    return GuideModel(
      name: json['name'],
      level: json['level'],
      materials:
          (json['materials'] as List)
              .map((m) => InstructionMaterial.fromJson(m))
              .toList(),
      steps:
          (json['instructions'] as List)
              .map((s) => InstructionStep.fromJson(s))
              .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
      'materials': materials.map((m) => m.toMap()).toList(),
      'instructions': steps.map((s) => s.toMap()).toList(),
    };
  }
}
