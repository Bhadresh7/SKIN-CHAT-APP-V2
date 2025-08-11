import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:skin_app_migration/core/constants/app_assets.dart';
import 'package:skin_app_migration/core/extensions/provider_extensions.dart';
import 'package:skin_app_migration/core/router/app_router.dart';
import 'package:skin_app_migration/core/theme/app_styles.dart';
import 'package:skin_app_migration/features/about/terms_and_conditions.dart';
import 'package:skin_app_migration/features/auth/providers/my_auth_provider.dart';
import 'package:skin_app_migration/features/profile/screens/edit_profile_screen.dart';
import 'package:skin_app_migration/features/super_admin/screens/view_all_users_screen.dart';

import '../../features/about/about_screen.dart';

class KBackgroundScaffold extends StatefulWidget {
  const KBackgroundScaffold({
    super.key,
    required this.body,
    this.loading = false,
    this.appBar,
    this.showDrawer = false,
    this.margin,
  });

  final Widget body;
  final bool loading;

  final PreferredSizeWidget? appBar;
  final bool showDrawer;
  final EdgeInsetsGeometry? margin;

  @override
  State<KBackgroundScaffold> createState() => _BackgroundScaffoldState();
}

class _BackgroundScaffoldState extends State<KBackgroundScaffold> {
  @override
  void initState() {
    super.initState();

    // Future.microtask(() {
    //   Provider.of<AppVersionProvider>(context, listen: false).fetchAppVersion();
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      drawer: widget.showDrawer
          ? Drawer(
              backgroundColor: AppStyles.primary,
              child: Column(
                children: [
                  // Header section with user info
                  SizedBox(
                    height: 0.27.sh,
                    child: UserAccountsDrawerHeader(
                      margin: EdgeInsets.only(top: 0),
                      currentAccountPictureSize: Size(0.25.sw, 0.25.sw),
                      currentAccountPicture: CircleAvatar(
                        child: Builder(
                          builder: (context) {
                            return ClipOval(
                              child: CircleAvatar(
                                radius: 0.3.sw,
                                backgroundImage:
                                    context.readAuthProvider.userData!.isGoogle!
                                    ? NetworkImage(
                                        context
                                            .readAuthProvider
                                            .user!
                                            .photoURL!,
                                      )
                                    : context
                                              .readAuthProvider
                                              .userData!
                                              .imageUrl !=
                                          null
                                    ? NetworkImage(
                                        context
                                            .readAuthProvider
                                            .userData!
                                            .imageUrl!,
                                      )
                                    : AssetImage(AppAssets.profileImage),
                              ),
                            );
                          },
                        ),
                      ),
                      accountEmail: Text(context.readAuthProvider.user!.email!),
                      accountName: Text(
                        context.readAuthProvider.userData!.username ??
                            context.readAuthProvider.user!.displayName ??
                            "Unkownn",
                      ),
                      decoration: BoxDecoration(color: AppStyles.primary),
                    ),
                  ),

                  // White rounded section for menu items
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(color: Colors.white),
                      child: ListView(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.info_outline,
                              color: Colors.grey[700],
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                            title: Text(
                              'About',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                              AppRouter.back(context);
                              AppRouter.to(context, AboutUsScreen());
                            },
                          ),
                          ListTile(
                            leading: Icon(
                              Icons.edit_outlined,
                              color: Colors.grey[700],
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                            title: Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                              AppRouter.back(context);
                              AppRouter.to(context, EditProfileScreen());
                            },
                          ),

                          if (context.readAuthProvider.userData!.role ==
                              "super_admin")
                            ListTile(
                              leading: Icon(
                                Icons.person_outline,
                                color: Colors.grey[700],
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey[400],
                                size: 16,
                              ),
                              title: Text(
                                'View User',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 16,
                                ),
                              ),
                              onTap: () {
                                AppRouter.back(context);
                                AppRouter.to(context, ViewAllUsersScreen());
                              },
                            ),
                          ListTile(
                            leading: Icon(
                              Icons.description_outlined,
                              color: Colors.grey[700],
                            ),
                            title: Text(
                              'Terms & conditions',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                              AppRouter.to(context, TermsAndConditionsScreen());
                            },
                          ),
                          SizedBox(height: 20),
                          ListTile(
                            leading: Icon(
                              Icons.logout_sharp,
                              color: AppStyles.danger,
                            ),
                            title: Text(
                              'Logout',
                              style: TextStyle(
                                color: AppStyles.danger,
                                fontSize: 16,
                              ),
                            ),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      "Confirm Logout",
                                      style: TextStyle(
                                        fontSize: AppStyles.heading,
                                      ),
                                    ),
                                    content: Text(
                                      "Are you sure to Logout ?",
                                      style: TextStyle(
                                        fontSize: AppStyles.bodyText,
                                      ),
                                    ),

                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          AppRouter.back(context);
                                        },
                                        child: Text("No"),
                                      ),

                                      TextButton(
                                        onPressed: () {
                                          Provider.of<MyAuthProvider>(
                                            context,
                                            listen: false,
                                          ).signOut(context);
                                        },
                                        child: Text("Yes"),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: Stack(
        children: [
          Center(
            child: Container(
              margin:
                  widget.margin ??
                  EdgeInsets.symmetric(horizontal: AppStyles.hMargin),
              child: widget.body,
            ),
          ),
          if (widget.loading)
            Positioned(
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                  Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
