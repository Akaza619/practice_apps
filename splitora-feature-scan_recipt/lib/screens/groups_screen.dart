import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:splitora_app/controllers/group_controller.dart';
import 'package:splitora_app/theme/app_theme.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final GroupController controller = Get.put(GroupController());
  final TextEditingController titleController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Group"),
        backgroundColor: AppTheme.appBarColor,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.backgroundDecoration,
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: AppTheme.glassCardDecoration,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Group Logo Picker
                        Center(
                          child: GestureDetector(
                            onTap: controller.pickImage,
                            child: Obx(() {
                              return CircleAvatar(
                                radius: 40,
                                backgroundColor: AppTheme.avatarImageBackground,
                                backgroundImage:
                                    controller.groupImage.value != null
                                        ? FileImage(
                                          controller.groupImage.value!,
                                        )
                                        : null,
                                child:
                                    controller.groupImage.value == null
                                        ? const Icon(
                                          Icons.camera_alt,
                                          color: AppTheme.textPrimary,
                                          size: 30,
                                        )
                                        : null,
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Title Input
                        _buildTextField(
                          titleController,
                          "Group Title",
                          Icons.title,
                        ),
                        const SizedBox(height: 15),

                        // Amount Input
                        _buildTextField(
                          amountController,
                          "Total Amount (Optional)",
                          Icons.attach_money,
                          keyboard: TextInputType.number,
                        ),
                        const SizedBox(height: 15),

                        // Date Picker
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.inputFill,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: AppTheme.iconColor,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat('yyyy-MM-dd').format(selectedDate),
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          "Add Members",
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Search Bar
                        TextField(
                          controller: searchController,
                          onChanged: controller.searchUsers,
                          style: const TextStyle(color: AppTheme.textPrimary),
                          decoration: InputDecoration(
                            hintText: "Search by name or email...",
                            hintStyle: const TextStyle(
                              color: AppTheme.textTertiary,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppTheme.iconColor,
                            ),
                            filled: true,
                            fillColor: AppTheme.inputFill,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Member List
                        SizedBox(
                          height: 200,
                          child: Obx(() {
                            if (controller.filteredUsers.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No users found",
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: controller.filteredUsers.length,
                              itemBuilder: (context, index) {
                                var user = controller.filteredUsers[index];
                                return Obx(() {
                                  bool isSelected = controller.selectedMemberIds
                                      .contains(user['uid']);
                                  return ListTile(
                                    onTap: () =>
                                        controller.toggleSelection(user['uid']),
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.avatarBackground,
                                      child: Text(
                                        (user['firstName'] ?? 'U')[0]
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      user['displayName'] ?? 'Unknown',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      user['email'] ?? '',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                    trailing: Checkbox(
                                      value: isSelected,
                                      onChanged: (val) =>
                                          controller.toggleSelection(
                                        user['uid'],
                                      ),
                                      activeColor: AppTheme.checkboxActive,
                                      checkColor: AppTheme.checkboxCheck,
                                      side: const BorderSide(
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  );
                                });
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 20),

                        // Create Button
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              controller.createGroup(
                                titleController.text.trim(),
                                amountController.text.trim(),
                                selectedDate,
                              );
                              titleController.clear();
                              amountController.clear();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.fabBackground,
                              foregroundColor: AppTheme.buttonForeground,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 15,
                              ),
                            ),
                            child: const Text(
                              "CREATE GROUP",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.iconColor),
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textTertiary),
        filled: true,
        fillColor: AppTheme.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
      ),
    );
  }
}
