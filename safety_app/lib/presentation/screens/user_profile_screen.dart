import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safety_app/core/constants/app_colors.dart';
import 'package:safety_app/core/repositories/user_profile_repository.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _aadhaarController = TextEditingController();

  String _selectedGender = 'Not Specified';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ref.read(userProfileProvider.future);
    if (mounted) {
      setState(() {
        _nameController.text = profile.name;
        _dobController.text = profile.dob;
        _selectedGender = ['Male', 'Female', 'Other'].contains(profile.gender)
            ? profile.gender
            : 'Not Specified';
        _addressController.text = profile.address;
        _aadhaarController.text = profile.aadhaar;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final profile = UserProfile(
        name: _nameController.text.trim(),
        dob: _dobController.text.trim(),
        gender: _selectedGender,
        address: _addressController.text.trim(),
        aadhaar: _aadhaarController.text.trim(),
      );

      await ref.read(userProfileRepositoryProvider).saveProfile(profile);
      ref.invalidate(userProfileProvider);

      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile data securely encrypted and saved"),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Photo
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor:
                          AppColors.primaryGreen.withValues(alpha: 0.1),
                      child: const Icon(Icons.person,
                          size: 60, color: AppColors.primaryGreen),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    )
                  ],
                ),
                const SizedBox(height: 32),

                // Verification Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBadge(Icons.phone_android, "Phone Verified", true),
                    _buildBadge(Icons.email_outlined, "Email Verified", false),
                  ],
                ),
                const SizedBox(height: 32),

                // Form Fields
                _buildTextField(
                  controller: _nameController,
                  label: "Full Name",
                  icon: Icons.person_outline,
                  validator: (v) => v!.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _dobController,
                  label: "Date of Birth (DD/MM/YYYY)",
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.datetime,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: "Gender",
                    prefixIcon: const Icon(Icons.people_outline,
                        color: AppColors.primaryGreen),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  initialValue: _selectedGender,
                  items: ['Not Specified', 'Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGender = v!),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _addressController,
                  label: "Full Home Address",
                  icon: Icons.home_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _aadhaarController,
                  label: "Aadhaar Number (Encrypted)",
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  isSecure: true,
                ),
                const SizedBox(height: 40),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text(
                            "SAVE SECURELY",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text("Secured with AES-256 Encryption",
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool isSecure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: isSecure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primaryGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, bool isVerified) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: isVerified
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isVerified
                ? AppColors.primaryGreen.withValues(alpha: 0.5)
                : Colors.red.withValues(alpha: 0.5),
          )),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 16,
              color: isVerified ? AppColors.primaryGreen : Colors.red),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: isVerified ? AppColors.primaryGreen : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Icon(isVerified ? Icons.check_circle : Icons.cancel,
              size: 14,
              color: isVerified ? AppColors.primaryGreen : Colors.red),
        ],
      ),
    );
  }
}
