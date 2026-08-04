import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/icons/app_icons.dart';
import 'package:split_trip/data/model/group_model.dart';
import 'package:split_trip/modules/Group/screen/group_detail_screen.dart';
import 'package:split_trip/modules/Home/screen/widgets/trip_card_widget.dart';

class GroupListItem extends StatelessWidget {
  final GroupModel item;
  final Function(int groupId, String groupName) onDeleteConfirm;

  const GroupListItem({
    super.key,
    required this.item,
    required this.onDeleteConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final groupIcon = AppIcons.getIcon(item.iconName);
    final groupColor = Color(item.colorValue);
    final gradient = [
      groupColor,
      groupColor.withValues(alpha: 0.8),
    ];
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
        child: const Icon(
          Icons.delete_forever,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (_) async {
        if (item.id != null) {
          onDeleteConfirm(item.id!, item.name);
        }
        return false;
      },
      child: TripCard(
        title: item.name,
        members: subtitleText,
        amount: "₹ 0.00",
        statusText: "Active",
        icon: groupIcon,
        gradient: gradient,
        isOwe: false,
        onTap: () {
          Get.to(
            () => GroupDetailScreen(
              group: item,
              gradient: gradient,
              icon: groupIcon,
            ),
          );
        },
      ),
    );
  }
}
