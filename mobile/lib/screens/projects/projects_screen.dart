import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../provider/project_provider.dart';
import '../../widgets/card_widget.dart';
import 'Project_details_screen.dart';
import '../../models/project_model.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("All Projects")),
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return const Center(child: Text("No projects found"));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.separated(
              itemCount: projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final project = projects[index];
                final guide = project.guide!;

                return Center(
                  child: SizedBox(
                    width: 300,
                    child: DIYProjectCard(
                      title: guide.name,
                      description: project.category.isNotEmpty ? project.category[0] : "Unknown",
                      imagePath: project.generatedImageUrl,
                      level: guide.level,
                      onArrowTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProjectDetailPage(project: project),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}
