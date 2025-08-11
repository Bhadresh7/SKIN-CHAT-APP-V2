import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skin_app_migration/core/extensions/provider_extensions.dart';
import 'package:skin_app_migration/core/theme/app_styles.dart';
import 'package:skin_app_migration/core/widgets/k_background_scaffold.dart';
import 'package:skin_app_migration/core/widgets/k_custom_button.dart';
import 'package:skin_app_migration/features/super_admin/service/csv_download_service.dart';
import 'package:skin_app_migration/features/super_admin/widgets/UserListView.dart';

class ViewAllUsersScreen extends StatefulWidget {
  const ViewAllUsersScreen({super.key});

  @override
  State<ViewAllUsersScreen> createState() => _ViewAllUsersScreenState();
}

class _ViewAllUsersScreenState extends State<ViewAllUsersScreen> {
  late StreamController<double> progressController;
  final CsvDownloadService _csvService = CsvDownloadService();

  final List<String> chipLabels = ["All", "Employer", "Candidates", "Blocked"];
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    progressController = StreamController<double>();
  }

  @override
  void dispose() {
    progressController.close();
    super.dispose();
  }

  void _confirmDownload(String role) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Download"),
        content: Text("Do you want to download the CSV for $role users?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showProgressModal(role);
            },
            child: Text("Confirm", style: TextStyle(color: AppStyles.primary)),
          ),
        ],
      ),
    );
  }

  void _showProgressModal(String role) {
    progressController = StreamController<double>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StreamBuilder<double>(
        stream: progressController.stream,
        initialData: 0,
        builder: (_, snapshot) {
          final progress = snapshot.data ?? 0.0;
          return AlertDialog(
            title: const Text("Downloading CSV"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("${(progress * 100).toStringAsFixed(0)}%"),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: progress),
              ],
            ),
          );
        },
      ),
    );

    _csvService
        .fetchUserDetailsAndConvertToCsv(
          role: role,
          progressController: progressController,
        )
        .then((resultMessage) {
          Navigator.pop(context);
          progressController.close();
        });
  }

  void _showDownloadSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Download CSV by Role",
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16.h),
              ListTile(
                leading: Icon(Icons.group, color: AppStyles.primary),
                title: const Text("All Users"),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDownload("all");
                },
              ),
              ListTile(
                leading: Icon(Icons.person, color: AppStyles.primary),
                title: const Text("Candidate"),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDownload("user");
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.admin_panel_settings,
                  color: AppStyles.primary,
                ),
                title: const Text("Employer"),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDownload("admin");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return KBackgroundScaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.8.sh * 0.1),
        child: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            Padding(
              padding: EdgeInsets.only(top: 0.02.sh),
              child: KCustomButton(
                height: 0.09.sh,
                width: 0.50.sw,
                text: "Download CSV",
                onPressed: _showDownloadSheet,
                suffixIcon: Icons.file_download_outlined,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5.0,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StreamBuilder<Map<String, int>>(
            stream: context.readSuperAdminProvider.userAndAdminCountStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text(
                  "Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                );
              }
              final counts =
                  snapshot.data ??
                  {'all': 0, 'admin': 0, 'user': 0, 'blocked': 0};

              // Labels with corresponding keys from counts map
              final chipData = [
                {'label': 'All', 'key': 'all'},
                {'label': 'Employer', 'key': 'admin'},
                {'label': 'Candidate', 'key': 'user'},
                {'label': 'Blocked', 'key': 'blocked'},
              ];

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(chipData.length, (index) {
                      final label = chipData[index]['label']!;
                      final key = chipData[index]['key']!;
                      final count = counts[key] ?? 0;

                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5.w),
                        child: ChoiceChip(
                          showCheckmark: false,
                          label: Text(
                            "$label ($count)", // 👈 Add count here
                            style: TextStyle(
                              color: selectedIndex == index
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                          selected: selectedIndex == index,
                          selectedColor: AppStyles.primary,
                          onSelected: (_) {
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
          Expanded(child: UserListView(filter: chipLabels[selectedIndex])),
        ],
      ),
    );
  }
}
