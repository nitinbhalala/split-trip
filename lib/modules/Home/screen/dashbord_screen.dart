import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/button/icon_button.dart';
import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/modules/Settings/controller/profile_controller.dart';

class DashbordScreen extends StatelessWidget {
  const DashbordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get user name from ProfileController if registered
    final profileController = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : null;

    final trips = const [
      _TripData(
        title: "Goa Trip",
        members: "8 Members",
        statusText: "You owe ",
        amount: "₹1,250.00",
        isOwe: true,
        icon: Icons.beach_access_rounded,
        gradient: [Color(0xFF34D399), Color(0xFF059669)],
      ),
      _TripData(
        title: "Manali Trip",
        members: "6 Members",
        statusText: "You'll receive ",
        amount: "₹980.00",
        isOwe: false,
        icon: Icons.landscape_rounded,
        gradient: [Color(0xFF60A5FA), Color(0xFF2563EB)],
      ),
      _TripData(
        title: "Thailand Trip",
        members: "4 Members",
        statusText: "You owe ",
        amount: "₹760.00",
        isOwe: true,
        icon: Icons.temple_buddhist_rounded,
        gradient: [Color(0xFFFBBF24), Color(0xFFD97706)],
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: AppSize.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Top Header (Menu, Greeting, Notification) ─────────────
              Row(
                children: [
                  // Greeting Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (profileController != null)
                          Obx(() {
                            final name =
                                profileController.firstName.value.isNotEmpty
                                ? profileController.firstName.value
                                : "Roshan";
                            return Text(
                              "Hello, $name 👋",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: AppSize.sp(18),
                              ),
                            );
                          })
                        else
                          Text(
                            "Hello, Roshan 👋",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: AppSize.sp(18),
                            ),
                          ),
                        AppSize.gapH(2),
                        Text(
                          "Ready for another adventure?",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                            fontSize: AppSize.sp(12),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Notification Bell
                  AppIconButton(
                    color: Theme.of(context).colorScheme.surface,
                    icon: Icons.notifications,
                    iconColor: AppColors.black,
                    onPressed: () {},
                  ),
                ],
              ),

              AppSize.gapH(20),

              // ── 2. Top Summary Cards (You Owe & You'll Receive) ───────────
              Row(
                children: [
                  // You Owe Card
                  Expanded(
                    child: Container(
                      padding: AppSize.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.error.withValues(alpha: 0.12)
                            : const Color(0xFFFFF1F1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "You Owe",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: AppSize.sp(12),
                            ),
                          ),
                          AppSize.gapH(8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "₹ 2,340.00",
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                                fontSize: AppSize.sp(18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  AppSize.gapW(14),

                  // You'll Receive Card
                  Expanded(
                    child: Container(
                      padding: AppSize.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : const Color(0xFFEFFDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "You'll Receive",
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: AppSize.sp(12),
                            ),
                          ),
                          AppSize.gapH(8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "₹ 4,250.00",
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: AppSize.sp(18),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              AppSize.gapH(16),

              // ── 3. Net Balance Card with Settle Up Button ────────────────
              Container(
                padding: AppSize.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : const Color(0xFFE8F7F0),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Net Balance",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: AppSize.sp(12),
                          ),
                        ),
                        AppSize.gapH(4),
                        Text(
                          "+ ₹ 1,910.00",
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: AppSize.sp(20),
                          ),
                        ),
                      ],
                    ),

                    // Settle Up Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        minimumSize: Size.zero,
                        padding: AppSize.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {},
                      child: Text(
                        "Settle Up",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: AppSize.sp(14),
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              AppSize.gapH(24),

              // ── 4. Your Trips Section Header ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Your Trips",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: AppSize.sp(18),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      "See All",
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: AppSize.sp(14),
                      ),
                    ),
                  ),
                ],
              ),

              AppSize.gapH(14),

              // ── 5. Trip List Items ────────────────────────────────────────
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trips.length,
                separatorBuilder: (context, index) => AppSize.gapH(12),
                itemBuilder: (context, index) {
                  final trip = trips[index];
                  return Container(
                    padding: AppSize.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.border.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Trip Thumbnail Icon
                        Container(
                          width: AppSize.w(52),
                          height: AppSize.w(52),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: trip.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            trip.icon,
                            color: AppColors.white,
                            size: AppSize.sp(26),
                          ),
                        ),

                        AppSize.gapW(14),

                        // Trip Details (Title & Members)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: AppSize.sp(15),
                                ),
                              ),
                              AppSize.gapH(4),
                              Text(
                                trip.members,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                  fontSize: AppSize.sp(12),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Amount Status
                        RichText(
                          textAlign: TextAlign.end,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: trip.statusText,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: AppSize.sp(12),
                                  fontWeight: FontWeight.w500,
                                  color: trip.isOwe
                                      ? AppColors.error
                                      : AppColors.primary,
                                ),
                              ),
                              TextSpan(
                                text: trip.amount,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: AppSize.sp(13),
                                  fontWeight: FontWeight.bold,
                                  color: trip.isOwe
                                      ? AppColors.error
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              AppSize.gapH(20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripData {
  final String title;
  final String members;
  final String statusText;
  final String amount;
  final bool isOwe;
  final IconData icon;
  final List<Color> gradient;

  const _TripData({
    required this.title,
    required this.members,
    required this.statusText,
    required this.amount,
    required this.isOwe,
    required this.icon,
    required this.gradient,
  });
}
