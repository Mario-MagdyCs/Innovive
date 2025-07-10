import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../provider/profile_provider.dart';
import 'Edit_profile_screen.dart';
import '../../models/menu_item_model.dart';

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return null;
  return await ProfileProvider.fetchUserProfile(uid);
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Color darkGreen = const Color(0xFF2E7D32);
    final profileAsync = ref.watch(userProfileProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(
          color: Theme.of(context).iconTheme.color,
        ),
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('❌ Error: $e')),
        data: (profile) {
          final fullName = profile?['full_name'] ?? 'User';
          final recycleCount = profile?['recycle_count'] ?? 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Profile header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/profile.jpg'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Enthusiast',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$recycleCount times',
                      style: TextStyle(
                        fontSize: 13,
                        color: darkGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔹 Menu items
              Expanded(
                child: ListView.separated(
                  itemCount: profileMenuItems.length,
                  separatorBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Divider(
                      color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                      thickness: 1,
                      height: 1,
                    ),
                  ),
                  itemBuilder: (context, index) {
                    final item = profileMenuItems[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: Icon(item.icon, color: darkGreen),
                      title: Text(
                        item.title,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).iconTheme.color?.withOpacity(0.6)),
                      onTap: () async {
                        if (item.title == 'Edit Profile') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const EditProfilePage()),
                          );
                        } else if (item.title == 'Log Out') {
                          await Supabase.instance.client.auth.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        } else if (item.title == 'Settings') {
                          if (context.mounted) {
                            Navigator.pushNamed(context, '/setting');
                          }
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
