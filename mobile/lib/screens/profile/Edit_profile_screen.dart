import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_controller.dart';
import '../../widgets/edit_profile_input_field.dart';
import '../../widgets/gender_option.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<Map<String, dynamic>>>(
  (ref) => ProfileController(),
);

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String gender = 'Male';
  bool hasChanged = false;
  bool _initialized = false;
  bool isSaving = false;
  String? currentlyEditingField;

  @override
  void initState() {
    super.initState();
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid != null) {
      ref.read(profileControllerProvider.notifier).loadProfile(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryGreen = const Color(0xFF5E9D7E);
    final appbarColor = isDarkMode ? scaffoldColor : primaryGreen;
    final buttonColor = isDarkMode ? Colors.black : primaryGreen;
    final effectiveButtonColor = hasChanged ? buttonColor : buttonColor.withOpacity(0.5);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => currentlyEditingField = null);
      },
      child: Scaffold(
        backgroundColor: appbarColor,
        appBar: AppBar(
          backgroundColor: appbarColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: const Text(
            'Edit profile',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: state.when(
          data: (profile) {
            if (!_initialized) {
              nameController.text = profile['full_name'] ?? '';
              emailController.text = profile['email'] ?? '';
              phoneController.text = profile['phone'] ?? '';
              gender = profile['gender'] ?? 'Male';
              _initialized = true;
            }

            return Column(
              children: [
                const SizedBox(height: 12),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 48,
                      backgroundImage: AssetImage('assets/profile.jpg'),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 120,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).cardColor.withOpacity(0.9),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: scaffoldColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          EditProfileInputField(
                            label: "Full Name",
                            controller: nameController,
                            isEditable: currentlyEditingField == "Full Name",
                            onEditToggle: () => setState(() {
                              currentlyEditingField = currentlyEditingField == "Full Name" ? null : "Full Name";
                            }),
                            validator: (value) =>
                                value == null || value.trim().isEmpty ? 'Full Name is required' : null,
                            onChanged: (_) => setState(() => hasChanged = true),
                          ),
                          const SizedBox(height: 16),
                          EditProfileInputField(
                            label: "Phone Number",
                            controller: phoneController,
                            isEditable: currentlyEditingField == "Phone Number",
                            onEditToggle: () => setState(() {
                              currentlyEditingField = currentlyEditingField == "Phone Number" ? null : "Phone Number";
                            }),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) return 'Phone Number is required';
                              if (!RegExp(r'^(01)[0-9]{9}$').hasMatch(trimmed)) {
                                return 'Enter valid Egyptian phone number';
                              }
                              return null;
                            },
                            onChanged: (_) => setState(() => hasChanged = true),
                          ),
                          const SizedBox(height: 16),
                          EditProfileInputField(
                            label: "E-mail",
                            controller: emailController,
                            isEditable: false,
                            showEditIcon: false,
                          ),
                          const SizedBox(height: 24),
                          Text("Gender", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 16)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              GenderOption(
                                option: "Male",
                                selected: gender,
                                onTap: () => setState(() {
                                  gender = "Male";
                                  hasChanged = true;
                                }),
                              ),
                              const SizedBox(width: 12),
                              GenderOption(
                                option: "Female",
                                selected: gender,
                                onTap: () => setState(() {
                                  gender = "Female";
                                  hasChanged = true;
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 36),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: effectiveButtonColor,
                                elevation: hasChanged ? 3 : 0,
                                shadowColor: Colors.black26,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: hasChanged && !isSaving
                                  ? () async {
                                      if (!_formKey.currentState!.validate()) return;
                                      FocusScope.of(context).unfocus();
                                      setState(() => isSaving = true);

                                      final uid = Supabase.instance.client.auth.currentUser?.id;
                                      if (uid == null) return;

                                      await ref.read(profileControllerProvider.notifier).updateProfile(uid, {
                                        'full_name': nameController.text.trim(),
                                        'phone': phoneController.text.trim(),
                                        'gender': gender,
                                      });

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Profile updated successfully")),
                                      );

                                      setState(() {
                                        isSaving = false;
                                        hasChanged = false;
                                        currentlyEditingField = null;
                                      });
                                    }
                                  : null,
                              child: isSaving
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : const Text("Save", style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }
}
