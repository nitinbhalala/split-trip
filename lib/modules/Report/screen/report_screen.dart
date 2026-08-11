import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/loader/app_loader.dart';
import 'package:split_trip/core/common/widgets/common_app_bar.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/mainScreen/main_controller.dart';
import 'package:split_trip/modules/Report/controller/report_controller.dart';
import 'package:split_trip/modules/Report/screen/widgets/report_expense_distribution.dart';
import 'package:split_trip/modules/Report/screen/widgets/report_group_selector.dart';
import 'package:split_trip/modules/Report/screen/widgets/report_member_breakdown_tile.dart';
import 'package:split_trip/modules/Report/screen/widgets/report_summary_card.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late final ReportController _controller;
  Worker? _tabWorker;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ReportController>()
        ? Get.find<ReportController>()
        : Get.put(ReportController());
    _controller.loadGroups();

    if (Get.isRegistered<MainController>()) {
      final mainController = Get.find<MainController>();
      _tabWorker = ever(mainController.currentIndex, (index) {
        if (index == 1) {
          _controller.loadGroups();
        }
      });
    }
  }

  @override
  void dispose() {
    _tabWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CommonAppBar(
        title: "Expense Report",
        showBackButton: false,
      ),
      body: Obx(() {
        if (_controller.isLoading.value &&
            _controller.selectedGroup.value == null) {
          return Center(child: AppLoader());
        }

        if (_controller.groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pie_chart_outline_rounded,
                  size: AppSize.sp(60),
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                AppSize.gapH(12),
                Text(
                  "No groups created yet.",
                  style: theme.textTheme.titleMedium,
                ),
                AppSize.gapH(4),
                Text(
                  "Create a group and add expenses to view analytics.",
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _controller.loadGroups();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSize.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Group Selector ──────────────────────────────────────
                ReportGroupSelector(controller: _controller),
                AppSize.gapH(16),

                // ── 2. Total Expense Summary Card ──────────────────────────
                ReportSummaryCard(controller: _controller),
                AppSize.gapH(10),

                // ── 3. Expense Distribution (Donut Chart) ──────────────────
                ReportExpenseDistribution(controller: _controller),
                AppSize.gapH(10),

                // ── 4. Member Expense Breakdown List ───────────────────────
                Text("Member Breakdown", style: theme.textTheme.titleMedium),
                AppSize.gapH(9),

                if (_controller.members.isEmpty)
                  Center(
                    child: Padding(
                      padding: AppSize.all(20.0),
                      child: const Text("No members found in this group."),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _controller.members.length,
                    separatorBuilder: (_, _) => AppSize.gapH(8),
                    itemBuilder: (context, index) {
                      final member = _controller.members[index];
                      return ReportMemberBreakdownTile(
                        member: member,
                        controller: _controller,
                      );
                    },
                  ),
                AppSize.gapH(24),
              ],
            ),
          ),
        );
      }),
    );
  }
}
