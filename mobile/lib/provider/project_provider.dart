import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';

// Service Provider
final projectServiceProvider = Provider((ref) => ProjectService());

// READ PROVIDER
final projectsProvider = FutureProvider<List<ProjectModel>>((ref) async {
  final service = ref.watch(projectServiceProvider);
  return await service.fetchProjects();
});

// WRITE PROVIDER (StateNotifier)
class ProjectController extends StateNotifier<AsyncValue<void>> {
  ProjectController(this.service) : super(const AsyncData(null));

  final ProjectService service;

  Future<void> saveProject(ProjectModel project) async {
    state = const AsyncLoading();
    try {
      await service.saveProject(project);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final projectControllerProvider =
    StateNotifierProvider<ProjectController, AsyncValue<void>>(
      (ref) => ProjectController(ref.watch(projectServiceProvider)),
    );
