import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/helper/app_helper.dart';
import 'package:split_trip/core/common/icons/app_icons.dart';
import 'package:split_trip/core/router/app_pages.dart';
import 'package:split_trip/data/model/group_model.dart';
import 'package:split_trip/modules/Group/screen/widgets/trip_card_widget.dart';
import 'package:split_trip/modules/Settings/controller/currency_controller.dart';

class GroupListItem extends StatelessWidget {
  final GroupModel item;
  final double totalExpense;
  final Function(int groupId, String groupName) onDeleteConfirm;

  const GroupListItem({
    super.key,
    required this.item,
    this.totalExpense = 0.0,
    required this.onDeleteConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final groupIcon = AppIcons.getIcon(item.iconName);
    final groupColor = Color(item.colorValue);
    final gradient = [groupColor, groupColor.withValues(alpha: 0.8)];
    final subtitleText = item.description.isNotEmpty
        ? item.description
        : "Created on ${item.createdAt?.split('T').first ?? 'Today'}";

    return Dismissible(
      key: Key('group_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        if (item.id != null) {
          onDeleteConfirm(item.id!, item.name);
        }
        return false;
      },
      child: Obx(() {
        final symbol = Get.isRegistered<CurrencyController>()
            ? Get.find<CurrencyController>().selectedCurrency.value.symbol
            : '₹';
        return TripCard(
          title: item.name,
          members: subtitleText,
          amount: AppHelper.formatCurrency(totalExpense, symbol: symbol),
          // statusText: "Active",
          icon: groupIcon,
          gradient: gradient,
          imagePath: item.imagePath,
          // isOwe: false,
          onTap: () {
            Get.toNamed(
              AppRoutes.groupDetail,
              arguments: item,
            );
          },
        );
      }),
    );
  }
}
