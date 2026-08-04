import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/button/app_elevated_button.dart';
import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/modules/Home/screen/widgets/summary_card.dart';
import 'package:split_trip/modules/Home/screen/widgets/trip_card_widget.dart';
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (profileController != null)
              Obx(() {
                final name = profileController.firstName.value.isNotEmpty
                    ? profileController.firstName.value
                    : "User";
                return Text(
                  "Hello, $name 👋",
                  style: theme.textTheme.titleLarge,
                );
              })
            else
              Text("Hello, User 👋", style: theme.textTheme.titleLarge),
            AppSize.gapH(2),
            Text(
              "Ready for another adventure?",
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actionsPadding: AppSize.symmetric(horizontal: 10),
        actions: [
          // AppIconButton(
          //   height: AppSize.h(38),
          //   width: AppSize.w(38),
          //   iconSize: AppSize.sp(25),
          //   borderRadius: 8,
          //   color: Theme.of(context).colorScheme.onSecondary,
          //   icon: Icons.notifications_none_sharp,
          //   iconColor: AppColors.black.withValues(alpha: 0.8),
          //   onPressed: () {},
          // ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_none_sharp),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: AppSize.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SummaryAmountCard(
                      title: "You Owe",
                      amount: "2,340.00",
                      color: AppColors.error,
                      isDark: isDark,
                    ),
                  ),

                  AppSize.gapW(14),

                  Expanded(
                    child: SummaryAmountCard(
                      title: "You'll Receive",
                      amount: "4,250.00",
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              AppSize.gapH(14),

              // ── 3. Net Balance Card with Settle Up Button ────────────────
              AppCard(
                padding: AppSize.symmetric(horizontal: 12, vertical: 10),

                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.07),
                // borderRadius: BorderRadius.circular(18),
                borderColor: AppColors.primary.withValues(alpha: 0.3),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Net Balance",
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        AppSize.gapH(4),
                        Text(
                          "1,910.00",
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    // Settle Up Button
                    AppElevatedButton(
                      width: AppSize.w(90),
                      height: AppSize.h(40),
                      borderRadius: 9,
                      onPressed: () {},
                      title: "Settle Up",
                    ),
                  ],
                ),
              ),

              AppSize.gapH(20),

              // ── 4. Your Trips Section Header ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Your Trips",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: AppSize.sp(18),
                    ),
                  ),
                  // GestureDetector(
                  //   onTap: () {},
                  //   child: Text(
                  //     "See All",
                  //     style: theme.textTheme.titleSmall?.copyWith(
                  //       color: AppColors.primary,
                  //       fontWeight: FontWeight.w500,
                  //       fontSize: AppSize.sp(14),
                  //     ),
                  //   ),
                  // ),
                ],
              ),

              AppSize.gapH(14),

              // ── 5. Trip List Items ────────────────────────────────────────
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: trips.length,
                separatorBuilder: (_, __) => AppSize.gapH(8),
                itemBuilder: (_, index) {
                  final trip = trips[index];

                  return TripCard(
                    title: trip.title,
                    members: trip.members,
                    amount: trip.amount,
                    statusText: trip.statusText,
                    icon: trip.icon,
                    gradient: trip.gradient,
                    isOwe: trip.isOwe,
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
