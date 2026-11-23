import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_theme.dart';

/// Building blocks of the "বিসিএস Edition" redesign. Every screen is built from
/// these so spacing, radii and colors stay identical across the app.

TextStyle dsText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = AppColors.ink,
  double? height,
}) {
  return AppTheme.font(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

/// White surface with a hairline border. Tappable when [onTap] is set.
class DsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double radius;

  const DsCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = AppColors.paper,
    this.borderColor = AppColors.line,
    this.borderWidth = 1,
    this.radius = 16,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: borderWidth == 0
          ? BorderSide.none
          : BorderSide(color: borderColor, width: borderWidth),
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Small grey label that heads a section ("আজ", "পরীক্ষা", "আরও").
class SectionLabel extends StatelessWidget {
  final String text;
  final String? trailing;

  const SectionLabel(this.text, {this.trailing, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            text,
            style: dsText(13, weight: FontWeight.w600, color: AppColors.ink2),
          ),
        ),
        if (trailing != null)
          Text(trailing!, style: dsText(12, color: AppColors.muted)),
      ],
    );
  }
}

/// Orange pill with a dot, used for anything live or running.
class LivePill extends StatelessWidget {
  final String text;

  const LivePill(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.liveSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const LiveDot(),
          const SizedBox(width: 6),
          Text(
            text,
            style: dsText(
              12,
              weight: FontWeight.w600,
              color: AppColors.liveInk,
            ),
          ),
        ],
      ),
    );
  }
}

class LiveDot extends StatelessWidget {
  const LiveDot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.live,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Neutral grey pill ("শেষ").
class NeutralPill extends StatelessWidget {
  final String text;

  const NeutralPill(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBE6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: dsText(12, weight: FontWeight.w600, color: AppColors.ink2),
      ),
    );
  }
}

/// Thin rounded progress bar.
class DsBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color track;
  final double height;

  const DsBar({
    required this.value,
    this.color = AppColors.brand,
    this.track = AppColors.line,
    this.height = 4,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return Container(
      height: height,
      decoration: BoxDecoration(color: track, borderRadius: radius),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0, 1).toDouble(),
        child: Container(
          decoration: BoxDecoration(color: color, borderRadius: radius),
        ),
      ),
    );
  }
}

/// Two-column grid of equal-width cells; each row is as tall as its tallest
/// cell.
class DsGrid extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  final double gap;

  const DsGrid({
    required this.children,
    this.columns = 2,
    this.gap = 8,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final cells = <Widget>[];
      for (var j = 0; j < columns; j++) {
        if (j > 0) cells.add(SizedBox(width: gap));
        final index = i + j;
        cells.add(
          Expanded(
            child: index < children.length
                ? children[index]
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: gap));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

/// A grid cell: a title on top and one line of useful info under it.
class InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool highlighted;
  final Color? subtitleColor;
  final Widget? subtitleLeading;
  final double titleSize;
  final double minHeight;

  const InfoTile({
    required this.title,
    required this.subtitle,
    this.onTap,
    this.highlighted = false,
    this.subtitleColor,
    this.subtitleLeading,
    this.titleSize = 15,
    this.minHeight = 76,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DsCard(
      onTap: onTap,
      radius: 14,
      borderColor: highlighted ? AppColors.brand : AppColors.line,
      borderWidth: highlighted ? 1.5 : 1,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight - 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: dsText(titleSize, weight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              children: [
                if (subtitleLeading != null) ...[
                  subtitleLeading!,
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    subtitle,
                    style: dsText(12, color: subtitleColor ?? AppColors.muted),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small grey box with a label and a value ("প্রশ্ন · ২৫").
class StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color background;
  final Color valueColor;
  final double valueSize;
  final Border? border;

  const StatBox({
    required this.label,
    required this.value,
    this.background = AppColors.canvas,
    this.valueColor = AppColors.ink,
    this.valueSize = 15,
    this.border,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: dsText(12, color: AppColors.muted)),
          Text(
            value,
            style: dsText(
              valueSize,
              weight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header used on inner pages: back (or close) button, title, subtitle and
/// an optional trailing widget.
class DsHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool close;
  final bool bordered;
  final double titleSize;
  final VoidCallback? onBack;

  const DsHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.close = false,
    this.bordered = true,
    this.titleSize = 18,
    this.onBack,
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: bordered
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: close ? 'বন্ধ করো' : 'ফিরে যাও',
                onPressed: onBack ?? () => _back(context),
                icon: Icon(
                  close ? LucideIcons.x : LucideIcons.chevronLeft,
                  size: 22,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: dsText(
                        titleSize,
                        weight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: dsText(12, color: AppColors.muted),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
            ],
          ),
        ),
      ),
    );
  }

  static void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}

/// iOS-style segmented control on a light grey track.
class DsSegmented<T> extends StatelessWidget {
  final List<(T, String, IconData?)> items;
  final T value;
  final ValueChanged<T> onChanged;
  final double height;
  final double fontSize;
  final bool expand;

  const DsSegmented({
    required this.items,
    required this.value,
    required this.onChanged,
    this.height = 34,
    this.fontSize = 13,
    this.expand = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = items.map((item) {
      final selected = item.$1 == value;
      final button = Semantics(
        selected: selected,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(item.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.paper : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: selected ? AppShadows.segment : null,
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.$3 != null) ...[
                  Icon(
                    item.$3,
                    size: 16,
                    color: selected ? AppColors.ink : AppColors.ink2,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  item.$2,
                  style: dsText(
                    fontSize,
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AppColors.ink : AppColors.ink2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return expand ? Expanded(child: button) : button;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.segment,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: buttons,
      ),
    );
  }
}

/// Filter chip: black when selected, outlined otherwise.
class DsChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double height;

  const DsChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.height = 36,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.ink : AppColors.paper,
      shape: StadiumBorder(
        side: selected
            ? BorderSide.none
            : const BorderSide(color: AppColors.lineStrong),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          alignment: Alignment.center,
          child: Text(
            label,
            style: dsText(
              13,
              weight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary (filled blue) and secondary (outlined) buttons.
class DsButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final double height;
  final double fontSize;
  final Color? background;
  final Color? foreground;

  const DsButton({
    required this.label,
    required this.onPressed,
    this.primary = true,
    this.height = 46,
    this.fontSize = 15,
    this.background,
    this.foreground,
    super.key,
  });

  const DsButton.secondary({
    required this.label,
    required this.onPressed,
    this.height = 46,
    this.fontSize = 14,
    super.key,
  }) : primary = false,
       background = null,
       foreground = null;

  @override
  Widget build(BuildContext context) {
    final bg = background ?? (primary ? AppColors.brand : AppColors.paper);
    final fg = foreground ?? (primary ? Colors.white : AppColors.ink);
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: primary
            ? BorderSide.none
            : const BorderSide(color: AppColors.lineStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: dsText(fontSize, weight: FontWeight.w600, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small outlined button used inline in rows ("অনুসরণ করো", "অনুশীলন").
class DsSmallButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  const DsSmallButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.ink : AppColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: filled
            ? BorderSide.none
            : const BorderSide(color: AppColors.lineStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: dsText(
              13,
              weight: FontWeight.w600,
              color: filled ? Colors.white : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rows inside one card separated by hairlines.
class DsListCard extends StatelessWidget {
  final List<Widget> children;
  final double radius;

  const DsListCard({required this.children, this.radius = 14, super.key});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(const Divider(height: 1, color: AppColors.lineSoft));
      }
      items.add(children[i]);
    }
    return DsCard(
      padding: EdgeInsets.zero,
      radius: radius,
      child: Column(children: items),
    );
  }
}

/// Answer state of an option in practice / competition / review.
enum OptionState { idle, picked, correct, wrong, dimmed }

/// Answer option with the ক/খ/গ/ঘ badge.
class OptionTile extends StatelessWidget {
  final String badge;
  final String label;
  final OptionState state;
  final VoidCallback? onTap;
  final String? note;
  final bool compact;

  const OptionTile({
    required this.badge,
    required this.label,
    this.state = OptionState.idle,
    this.onTap,
    this.note,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var border = AppColors.line;
    var bg = AppColors.paper;
    var badgeBg = AppColors.sunken;
    var badgeFg = AppColors.ink;
    var noteColor = AppColors.muted;
    switch (state) {
      case OptionState.idle:
      case OptionState.dimmed:
        break;
      case OptionState.picked:
        border = AppColors.brand;
        bg = AppColors.brandSoft;
        badgeBg = AppColors.brand;
        badgeFg = Colors.white;
      case OptionState.correct:
        border = AppColors.success;
        bg = AppColors.successSoft;
        badgeBg = AppColors.success;
        badgeFg = Colors.white;
        noteColor = AppColors.success;
      case OptionState.wrong:
        border = AppColors.danger;
        bg = AppColors.dangerSoft;
        badgeBg = AppColors.danger;
        badgeFg = Colors.white;
        noteColor = AppColors.danger;
    }
    final badgeSize = compact ? 26.0 : 30.0;
    return Opacity(
      opacity: state == OptionState.dimmed ? 0.55 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: compact ? 46 : 54),
            child: Padding(
              padding: compact
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: badgeSize,
                    height: badgeSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: badgeBg,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      badge,
                      style: dsText(
                        13,
                        weight: FontWeight.w700,
                        color: badgeFg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: dsText(compact ? 15 : 16, height: 1.4),
                    ),
                  ),
                  if (note != null && note!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      note!,
                      style: dsText(
                        12,
                        weight: FontWeight.w600,
                        color: noteColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Square icon holder used in list rows.
class IconSquare extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final double size;

  const IconSquare(this.icon, {this.filled = false, this.size = 40, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? AppColors.brand : AppColors.sunken,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 20, color: filled ? Colors.white : AppColors.ink),
    );
  }
}

/// Standard page body padding with vertical gaps between children.
class DsPage extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double gap;

  const DsPage({
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
    this.gap = 12,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(SizedBox(height: gap));
      items.add(children[i]);
    }
    return ListView(padding: padding, children: items);
  }
}

void showComingSoon(BuildContext context, [String what = 'এই অংশ']) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$what শীঘ্রই আসছে')));
}

/// Asks before something that is hard to undo. Returns true only when the
/// learner taps the confirm button; a tap outside or "থাক" returns false.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String cancelLabel = 'থাক',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: dsText(18, weight: FontWeight.w700)),
      content: message == null
          ? null
          : Text(
              message,
              style: dsText(14, color: AppColors.ink2, height: 1.5),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            cancelLabel,
            style: dsText(15, weight: FontWeight.w600, color: AppColors.muted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            confirmLabel,
            style: dsText(
              15,
              weight: FontWeight.w700,
              color: destructive ? AppColors.danger : AppColors.brand,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
