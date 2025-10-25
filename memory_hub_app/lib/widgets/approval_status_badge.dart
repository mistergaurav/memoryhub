import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget buildApprovalStatusBadge(String? approvalStatus) {
  if (approvalStatus == null || approvalStatus == 'draft') {
    return const SizedBox.shrink();
  }

  Color color;
  String text;
  IconData icon;

  switch (approvalStatus) {
    case 'pending_approval':
      color = Colors.orange;
      text = 'Pending';
      icon = Icons.pending;
      break;
    case 'approved':
      color = Colors.green;
      text = 'Approved';
      icon = Icons.check_circle;
      break;
    case 'rejected':
      color = Colors.red;
      text = 'Rejected';
      icon = Icons.cancel;
      break;
    default:
      return const SizedBox.shrink();
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.inter(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
