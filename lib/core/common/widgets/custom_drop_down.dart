import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:flutter/material.dart';

class DropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;

  const DropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.leading,
  });
}

class CustomDropdown<T> extends StatefulWidget {
  final String? title;
  final List<DropdownItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final bool enabled;
  final bool? isOpen;
  final VoidCallback? onTap;

  const CustomDropdown({
    super.key,
    this.title,
    required this.items,
    this.selectedValue,
    this.onChanged,
    this.hint,
    this.enabled = true,
    this.isOpen,
    this.onTap,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  bool _localIsOpen = false;

  bool get isOpen => widget.isOpen ?? _localIsOpen;

  @override
  void didUpdateWidget(covariant CustomDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && isOpen) {
      if (widget.onTap != null) {
        widget.onTap!();
      } else {
        setState(() {
          _localIsOpen = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Find currently selected item
    DropdownItem<T>? selectedItem;
    for (final item in widget.items) {
      if (item.value == widget.selectedValue) {
        selectedItem = item;
        break;
      }
    }

    final bool hasSelection =
        widget.selectedValue != null && selectedItem != null;
    final displayItem = hasSelection ? selectedItem : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Label (if provided)
        if (widget.title != null && widget.title!.isNotEmpty) ...[
          Text(
            widget.title!,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: AppSize.sp(14),
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          AppSize.gapH(8),
        ],

        // Dropdown Trigger Button
        GestureDetector(
          onTap: widget.enabled
              ? () {
                  if (widget.onTap != null) {
                    widget.onTap!();
                  } else {
                    setState(() {
                      _localIsOpen = !_localIsOpen;
                    });
                  }
                }
              : null,
          child: Container(
            padding: AppSize.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.enabled
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).disabledColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isOpen
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.outline.withValues(
                        alpha: widget.enabled ? 0.7 : 0.5,
                      ),
              ),
            ),
            child: Row(
              children: [
                if (displayItem?.leading != null) ...[
                  displayItem!.leading!,
                  AppSize.gapW(12),
                ] else if (displayItem?.icon != null) ...[
                  Icon(
                    displayItem!.icon,
                    size: 20,
                    color: displayItem.iconColor ?? AppColors.primary,
                  ),
                  AppSize.gapW(12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayItem?.label ?? widget.hint ?? "Select Item",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: AppSize.sp(14),
                          color: displayItem != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (displayItem?.subtitle != null) ...[
                        AppSize.gapH(2),
                        Text(
                          displayItem!.subtitle!,
                          style: TextStyle(
                            fontSize: AppSize.sp(11),
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),

        // Dropdown Items List
        if (isOpen) ...[
          AppSize.gapH(6),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ],
            ),
            child: Column(
              children: widget.items.map((item) {
                final isSelected = item.value == widget.selectedValue;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (widget.onChanged != null) {
                        widget.onChanged!(item.value);
                      }
                      if (widget.onTap != null) {
                        widget.onTap!();
                      } else {
                        setState(() {
                          _localIsOpen = false;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(2),
                    child: Padding(
                      padding: AppSize.symmetric(horizontal: 12, vertical: 5),
                      child: Row(
                        children: [
                          if (item.leading != null) ...[
                            item.leading!,
                            AppSize.gapW(12),
                          ] else if (item.icon != null) ...[
                            Icon(
                              item.icon,
                              size: 20,
                              color: isSelected
                                  ? AppColors.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            AppSize.gapW(12),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        fontSize: AppSize.sp(14),
                                        color: isSelected
                                            ? AppColors.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                      ),
                                ),
                                if (item.subtitle != null) ...[
                                  AppSize.gapH(2),
                                  Text(
                                    item.subtitle!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontSize: AppSize.sp(11),
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: AppColors.primary,
                              size: AppSize.sp(20),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
