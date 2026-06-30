import 'package:flutter/material.dart';
import '../qd_palette.dart';
import '../qd_tokens.dart';

/// Premium pill-shaped search bar — light grey fill, no harsh border.
/// Matches Swiggy/Zomato-style search inputs.
class QDSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  const QDSearchBar({
    super.key,
    required this.controller,
    this.placeholder = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: QDPalette.neutral50,
        borderRadius: BorderRadius.circular(QDRadius.searchBar),
        border: Border.all(color: QDPalette.neutral100),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: QDPalette.neutral800,
        ),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: const TextStyle(
            fontSize: 14,
            color: QDPalette.neutral300,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 14, right: 8),
            child: Icon(Icons.search_rounded, size: 20, color: QDPalette.neutral400),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 44),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, val, __) {
              if (val.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: QDPalette.neutral300,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
                onPressed: () {
                  controller.clear();
                  onClear?.call();
                },
              );
            },
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          isDense: true,
        ),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
      ),
    );
  }
}
