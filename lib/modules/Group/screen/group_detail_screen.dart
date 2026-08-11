import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/button/app_elevated_button.dart';
import 'package:split_trip/core/common/loader/app_loader.dart';
import 'package:split_trip/core/router/app_pages.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/data/model/expense_metadata_model.dart';
import 'package:split_trip/data/model/group_message_model.dart';
import 'package:split_trip/data/model/group_model.dart';
import 'package:split_trip/modules/Group/controller/group_detail_controller.dart';
import 'package:split_trip/modules/Group/screen/widgets/add_people_bottom_sheet.dart';
import 'package:split_trip/modules/Group/screen/widgets/group_detail_app_bar.dart';
import 'package:split_trip/modules/Group/screen/widgets/group_detail_widgets.dart';

class GroupDetailScreen extends StatefulWidget {
  final GroupModel group;
  final List<Color>? gradient;
  final IconData? icon;

  const GroupDetailScreen({
    super.key,
    required this.group,
    this.gradient,
    this.icon,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final GroupDetailController _controller;
  late final TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final tag = "group_${widget.group.id}";
    _controller = Get.isRegistered<GroupDetailController>(tag: tag)
        ? Get.find<GroupDetailController>(tag: tag)
        : Get.put(GroupDetailController(groupId: widget.group.id!), tag: tag);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
      if (_tabController.index == 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: GroupDetailAppBar(
        group: widget.group,
        controller: _controller,
        tabController: _tabController,
        gradient: widget.gradient,
        icon: widget.icon,
      ),

      // Screen Body (TabBarView)
      body: SafeArea(
        bottom: true,
        top: false,
        child: TabBarView(
          controller: _tabController,
          children: [
            // ── Tab 1: Chat Feed ──────────────────────────────────────────────
            _buildChatTab(theme),
            // ── Tab 2: Expenses Summary Feed ──────────────────────────────────
            _buildExpensesTab(theme),
          ],
        ),
      ),

      // Pinned Bottom Bar (Only visible on Chat Tab - Index 0)
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: AnimatedBuilder(
          animation: _tabController.animation ?? _tabController,
          builder: (context, _) {
            final double animVal =
                _tabController.animation?.value ??
                _tabController.index.toDouble();
            if (animVal < 0.5) {
              return Padding(
                padding: AppSize.symmetric(horizontal: 100, vertical: 10),
                child: _buildBottomBar(theme),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showAddPeopleDialog() {
    AddPeopleBottomSheet.show(context, _controller);
  }

  // ── Chat Tab View ──────────────────────────────────────────────────────────
  Widget _buildChatTab(ThemeData theme) {
    return Obx(() {
      if (_controller.isLoading.value && _controller.messages.isEmpty) {
        return Center(child: AppLoader());
      }

      if (_controller.messages.isEmpty) {
        return GroupChatEmptyStateWidget(
          controller: _controller,
          onAddMemberTap: _showAddPeopleDialog,
        );
      }

      return ListView.builder(
        controller: _scrollController,
        padding: AppSize.symmetric(horizontal: 16, vertical: 12),
        itemCount: _controller.messages.length,
        itemBuilder: (context, index) {
          final msg = _controller.messages[index];

          if (msg.isExpense) {
            final meta = ExpenseMetadataModel.parse(msg, _controller.members);
            return GPaySplitCardWidget(
              msg: msg,
              members: _controller.members,
              onTap: () => _openExpenseDetailScreen(msg, meta),
              onEditTap: () => _openEditExpenseScreen(msg, meta),
            );
          } else {
            return TextChatBubbleWidget(msg: msg  );
          }
        },
      );
    });
  }

  // ── Expenses Tab View ──────────────────────────────────────────────────────
  Widget _buildExpensesTab(ThemeData theme) {
    return Obx(() {
      // Touch Rx observables to guarantee Obx subscription
      final _ = _controller.messages.length + _controller.members.length;

      if (_controller.activeExpenseMessages.isEmpty) {
        return const Center(child: Text("No expenses added yet."));
      }

      final netBalances = _controller.netBalances;
      final settlementList = _controller.settlementList;

      return SingleChildScrollView(
        padding: AppSize.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Group Expense Banner
            GroupTotalExpensesBannerWidget(
              totalExpense: _controller.totalGroupExpense,
            ),
            AppSize.gapH(16),

            // Overall Member Balances Section
            Text("Overall Balances", style: theme.textTheme.titleMedium),
            AppSize.gapH(8),
            OverallBalancesListWidget(
              netBalances: netBalances,
              memberSettledAmounts: _controller.memberSettledAmounts,
              onMarkPaid: (name) => _controller.markMemberAllPaid(name),
            ),
            AppSize.gapH(20),
            // Pending Settlements Section (Who owes Whom)
            Text("Pending Settlements", style: theme.textTheme.titleMedium),
            AppSize.gapH(8),
            PendingSettlementsListWidget(settlementList: settlementList),
          ],
        ),
      );
    });
  }

  // ── Open Full Screen Expense Detail ─────────────────────────────────────────
  void _openExpenseDetailScreen(
    GroupMessageModel msg,
    ExpenseMetadataModel meta,
  ) {
    Get.toNamed(
      AppRoutes.expenseDetail,
      arguments: {
        'msg': msg,
        'meta': meta,
        'controller': _controller,
      },
    );
  }

  // ── Open Full Screen Edit Expense ───────────────────────────────────────────
  void _openEditExpenseScreen(
    GroupMessageModel msg,
    ExpenseMetadataModel meta,
  ) {
    Get.toNamed(
      AppRoutes.addSplitExpense,
      arguments: {
        'controller': _controller,
        'groupName': widget.group.name,
        'editingMessage': msg,
        'initialMeta': meta,
      },
    );
  }

  // ── Pinned Bottom Action Bar ─────────────────────────────────────────────────
  Widget _buildBottomBar(ThemeData theme) {
    return AppElevatedButton(
      height: AppSize.h(38),
      borderRadius: 30,
      title: "Split an expense",
      icon: Icons.add_rounded,
      onPressed: () {
        Get.toNamed(
          AppRoutes.addSplitExpense,
          arguments: {
            'controller': _controller,
            'groupName': widget.group.name,
          },
        );
      },
    );
  }
}
