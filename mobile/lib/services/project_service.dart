import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project_model.dart';

class ProjectService {
  static final _client = Supabase.instance.client;

  Future<void> saveProject(ProjectModel project) async {
    final data = project.toJson();
    print("🟢🟢🟢🟢🟢🟢 Attempting to insert project: $data");

    final response = await _client.from('projects').insert(data);

    if (response.error != null) {
      print("🔴🔴🔴🔴🔴 Error inserting project: ${response.error!.message}");
    } else {
      print("✅✅✅✅✅✅ Project inserted successfully!");
    }
  }

  Future<List<ProjectModel>> fetchProjects() async {
    final response = await _client.from('projects').select();
    final data = response as List<dynamic>;
    print("🟢🔴🟢🔴🟢🔴 FETCHED THIS FROM THE DATABASE $data");
    return data.map((e) => ProjectModel.fromJsonDB(e)).toList();
  }
}
