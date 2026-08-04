import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:split_trip/core/common/button/app_elevated_button.dart';
import 'package:split_trip/core/common/widgets/app_auto_size_text.dart';
import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/data/model/group_model.dart';
import 'package:split_trip/modules/Group/controller/group_detail_controller.dart';
import 'package:split_trip/modules/Group/screen/add_split_expense_screen.dart';
import 'package:split_trip/modules/Group/screen/group_info_screen.dart';

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
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      GroupDetailController(groupId: widget.group.id ?? 0),
      tag: "group_${widget.group.id}",
    );
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final success = await _controller.sendMessage(text: text);
    if (success) {
      _scrollToBottom();
    }
  }

  void _openGroupInfo() {
    Get.to(
      () => GroupInfoScreen(
        group: widget.group,
        controller: _controller,
        gradient: widget.gradient,
        icon: widget.icon,
      ),
    );
  }

  void _openAddSplitExpense() {
    Get.to(
      () => AddSplitExpenseScreen(
        controller: _controller,
        groupName: _controller.groupName.value.isNotEmpty
            ? _controller.groupName.value
            : widget.group.name,
      ),
    )?.then((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // GPay Style AppBar with Chat & Expenses Tabs
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Get.back(),
        ),
        title: InkWell(
          onTap: _openGroupInfo,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: AppSize.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                // Group Avatar / Icon
                Container(
                  width: AppSize.w(35),
                  height: AppSize.h(35),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors:
                          widget.gradient ??
                          [AppColors.primary, AppColors.primaryDark],
                    ),
                  ),
                  child: Icon(
                    widget.icon ?? Icons.group_work_rounded,
                    color: AppColors.white,
                    size: AppSize.sp(22),
                  ),
                ),
                AppSize.gapW(10),

                // Group Name & Member count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => Text(
                          _controller.groupName.value.isNotEmpty
                              ? _controller.groupName.value
                              : widget.group.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Obx(() {
                        final count = _controller.members.length;
                        return Text(
                          "$count members",
                          style: theme.textTheme.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.more_vert_rounded),
        //     onPressed: _openGroupInfo,
        //   ),
        // ],
        // Header Tabs (Chat & Expenses) with Vertical Divider & Compact Spacing
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(AppSize.h(34)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelColor: theme.colorScheme.onSurface,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: theme.textTheme.titleMedium,
                dividerColor: Colors.transparent,
                labelPadding: AppSize.symmetric(horizontal: 24),
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(width: 3, color: AppColors.primary),
                ),
                indicatorSize: TabBarIndicatorSize.tab,

                tabs: [
                  Tab(height: AppSize.h(30), text: "Chat"),
                  Tab(height: AppSize.h(30), text: "Expenses"),
                ],
              ),
            ],
          ),
        ),
      ),

      // Screen Body (TabBarView)
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Chat Feed ──────────────────────────────────────────────
          _buildChatTab(theme),
          // ── Tab 2: Expenses Summary Feed ──────────────────────────────────
          _buildExpensesTab(theme),
        ],
      ),

      // Pinned Bottom Bar (Always visible at the bottom of the screen!)
      bottomNavigationBar: Padding(
        padding: AppSize.symmetric(horizontal: 100, vertical: 10),
        child: _buildBottomBar(theme),
      ),
    );
  }

  // ── Chat Tab View ──────────────────────────────────────────────────────────
  Widget _buildChatTab(ThemeData theme) {
    return Obx(() {
      if (_controller.isLoading.value && _controller.messages.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.messages.isEmpty) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: AppSize.sp(56),
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                    AppSize.gapH(12),
                    Text(
                      "No split requests in this group yet",
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSize.gapH(8),
                    Text(
                      "Tap 'Split expense' below to add a bill or split request!",
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _controller.messages.length,
        itemBuilder: (context, index) {
          final msg = _controller.messages[index];

          if (msg.isExpense) {
            // GPay Style Split Request Card
            return _buildGPaySplitCard(theme, msg);
          } else {
            // Text Chat Bubble
            return _buildTextChatBubble(theme, msg);
          }
        },
      );
    });
  }

  // ── Expenses Tab View ──────────────────────────────────────────────────────
  Widget _buildExpensesTab(ThemeData theme) {
    return Obx(() {
      final expenseMsgs = _controller.messages
          .where((m) => m.isExpense)
          .toList();

      if (expenseMsgs.isEmpty) {
        return const Center(child: Text("No expenses added yet."));
      }

      final double totalGroupExpense = expenseMsgs.fold(
        0.0,
        (sum, item) => sum + item.amount,
      );

      return Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  "Total Group Expenses",
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                AppSize.gapH(4),
                Text(
                  "₹ ${totalGroupExpense.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: expenseMsgs.length,
              itemBuilder: (context, index) {
                final item = expenseMsgs[index];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      item.messageText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(item.createdAt?.split('T').first ?? "Today"),
                    trailing: Text(
                      "₹ ${item.amount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  // ── GPay Style Split Request Card ──────────────────────────────────────────
  Widget _buildGPaySplitCard(ThemeData theme, dynamic msg) {
    String formattedTime = "";
    if (msg.createdAt != null) {
      try {
        final dt = DateTime.parse(msg.createdAt!);
        formattedTime = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    final double amount = msg.amount as double;
    final int memberCount = _controller.members.isNotEmpty
        ? _controller.members.length
        : 1;
    final double perPerson = amount / memberCount;

    return Align(
      alignment: Alignment.centerRight,
      child: AppCard(
        margin: AppSize.symmetric(vertical: 10),
        width: MediaQuery.of(context).size.width * 0.82,
        padding: AppSize.symmetric(vertical: 12, horizontal: 12),
        borderRadius: 15,
        borderColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Split request",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            AppSize.gapH(4),
            Text(
              "₹${amount.toStringAsFixed(0)}",
              style: theme.textTheme.headlineMedium,
            ),
            AppSize.gapH(1),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "₹${perPerson.toStringAsFixed(0)} / person ($memberCount members)",
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.75,
                      backgroundColor: theme.colorScheme.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
                AppSize.gapW(8),
                AppAutoSizeText(
                  text: "₹${perPerson.toStringAsFixed(0)}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            AppSize.gapH(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14),
                    AppSize.gapW(4),
                    Text(
                      formattedTime.isNotEmpty ? formattedTime : "Just now",
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Active Split",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Text Chat Bubble ───────────────────────────────────────────────────────
  Widget _buildTextChatBubble(ThemeData theme, dynamic msg) {
    final isMe = (msg.senderName as String).toLowerCase() == "me";

    String formattedTime = "";
    if (msg.createdAt != null) {
      try {
        final dt = DateTime.parse(msg.createdAt!);
        formattedTime = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  msg.senderName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            Text(
              msg.messageText,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
            if (formattedTime.isNotEmpty) ...[
              AppSize.gapH(4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Bottom Action Bar (Only "Split expense" Button) ────────────────────────
  Widget _buildBottomBar(ThemeData theme) {
    return AppElevatedButton(
      padding: AppSize.symmetric(vertical: 2, horizontal: 12),
      height: AppSize.h(40),
      borderRadius: 20,
      onPressed: _openAddSplitExpense,
      icon: Icons.call_split_rounded,
      iconSize: AppSize.sp(24),
      textStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
        color: AppColors.white,
        fontSize: AppSize.sp(16),
      ),
      title: "Split expense",
    );
  }
}
