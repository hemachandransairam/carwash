import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

PreferredSizeWidget buildGlobalAppBar({
  required BuildContext context,
  required String title,
  VoidCallback? onBack,
  PreferredSizeWidget? bottom,
  Color? titleColor, // Optional title color
  List<Widget>? actions, // Optional actions
  bool showBackButton = true, // Optional showBackButton
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading:
        showBackButton
            ? Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF01102B)),
                  onPressed: onBack ?? () => Navigator.pop(context),
                ),
              ),
            )
            : null,
    automaticallyImplyLeading:
        false, // Prevent default back button when leading is null
    title: Text(
      title,
      style: TextStyle(
        color:
            titleColor ??
            const Color(0xFF01102B), // Use custom color or default
        fontWeight: FontWeight.w800,
        fontSize: 20,
      ),
    ),
    centerTitle: true,
    actions: actions, // Add actions
    bottom: bottom,
  );
}

Widget buildServiceTile({
  required String title,
  required IconData icon,
  required bool isSelected,
  required VoidCallback onTap,
  double? price,
  double? mrp,
  String? saveText,
  List<String>? checklist,
  String? categoryBadge,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSelected ? const Color(0xFF01102B) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: const Color(0xFF01102B), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF01102B),
                            ),
                          ),
                        ),
                        if (categoryBadge != null)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: categoryBadge.contains("ELITE") ? const Color(0xFF2E3A59).withAlpha(20) : const Color(0xFF67B7ED).withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              categoryBadge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: categoryBadge.contains("ELITE") ? const Color(0xFF2E3A59) : const Color(0xFF1B6BA7),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (mrp != null) ...[
                          Text(
                            "₹${mrp.toStringAsFixed(0)}",
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              fontSize: 14,
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (price != null)
                          Text(
                            "₹${price.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              color: Color(0xFFD32F2F), // Red for offer price like image
                            ),
                          ),
                      ],
                    ),
                    if (saveText != null && saveText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        saveText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.green, // "You Save" color
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFF01102B), size: 28)
              else
                const Icon(Icons.circle_outlined, color: Colors.grey, size: 28),
            ],
          ),
          if (checklist != null && checklist.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: Color(0xFFF0F0F0)),
            const SizedBox(height: 12),
            ...checklist.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600, height: 1.4),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    ),
  );
}

Widget buildPrimaryButton({
  required String text,
  required VoidCallback? onTap,
}) {
  return SizedBox(
    width: double.infinity,
    height: 56,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF01102B),
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.grey[300],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 0,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    ),
  );
}

Widget buildCustomIconButton({
  required IconData icon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: const Color(0xFF01102B), size: 24),
    ),
  );
}

Widget buildDateCircle({
  required DateTime date,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 60,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF01102B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF01102B) : const Color(0xFFEEEEEE),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('E').format(date),
            style: TextStyle(
              color: isSelected ? Colors.white70 : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date.day.toString(),
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF01102B),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget buildTimeChip({
  required String time,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF01102B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF01102B) : const Color(0xFFEEEEEE),
        ),
      ),
      child: Text(
        time,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF01102B),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

Widget buildLocationInputField({
  required TextEditingController controller,
  required String hint,
  FocusNode? focusNode,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F6F6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        border: InputBorder.none,
        icon: const Icon(Icons.location_on, color: Color(0xFF01102B), size: 20),
      ),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Color(0xFF01102B),
      ),
    ),
  );
}

Widget buildSavedAddressTile({
  required String label,
  required String address,
  required bool isSelected,
  required VoidCallback onTap,
  required VoidCallback onDelete,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF01102B) : const Color(0xFFEEEEEE),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              label == 'Home' ? Icons.home_rounded : Icons.work_rounded,
              color: const Color(0xFF01102B),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF01102B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    ),
  );
}

Widget buildLabelChip({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF01102B) : const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF01102B),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
