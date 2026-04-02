import "package:flutter/material.dart";
import "package:mix/mix.dart";

class Button extends StatelessWidget {
  const Button({required this.label, this.onPressed, this.style, super.key});

  final String label;
  final VoidCallback? onPressed;
  final Style? style;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPress: onPressed,
      child: Box(style: style, child: StyledText(label)),
    );
  }
}
