import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../shared/theme/app_colors.dart';

/// Filter configuration for bookings.
class BookingFilter {
  const BookingFilter({
    this.statuses = const {},
    this.dateFrom,
    this.dateTo,
    this.proName,
  });

  final Set<String> statuses;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? proName;

  bool get isActive =>
      statuses.isNotEmpty ||
      dateFrom != null ||
      dateTo != null ||
      (proName != null && proName!.isNotEmpty);

  BookingFilter copyWith({
    Set<String>? statuses,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? proName,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return BookingFilter(
      statuses: statuses ?? this.statuses,
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      proName: proName ?? this.proName,
    );
  }
}

/// Bottom sheet for filtering bookings by status, date range, and pro.
class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  final BookingFilter currentFilter;
  final ValueChanged<BookingFilter> onApply;

  static Future<void> show(
    BuildContext context, {
    required BookingFilter currentFilter,
    required ValueChanged<BookingFilter> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(
        currentFilter: currentFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Set<String> _statuses;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  late final TextEditingController _proNameController;

  static List<(String, String, Color)> _statusOptions(AppLocalizations l) => [
    ('confirmed', l.confirmed, AppColors.success),
    ('pending_payment', l.pending, AppColors.violetClair),
    ('completed', l.markAsDone, AppColors.gris),
    ('cancelled_full_refund', l.cancel, AppColors.error),
    ('cancelled_no_refund', l.cancel, AppColors.error),
  ];

  @override
  void initState() {
    super.initState();
    _statuses = Set.of(widget.currentFilter.statuses);
    _dateFrom = widget.currentFilter.dateFrom;
    _dateTo = widget.currentFilter.dateTo;
    _proNameController =
        TextEditingController(text: widget.currentFilter.proName);
  }

  @override
  void dispose() {
    _proNameController.dispose();
    super.dispose();
  }

  void _apply() {
    HapticFeedback.lightImpact();
    widget.onApply(BookingFilter(
      statuses: _statuses,
      dateFrom: _dateFrom,
      dateTo: _dateTo,
      proName: _proNameController.text.trim().isEmpty
          ? null
          : _proNameController.text.trim(),
    ));
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _statuses = {};
      _dateFrom = null;
      _dateTo = null;
      _proNameController.clear();
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_dateFrom ?? DateTime.now())
        : (_dateTo ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.violet,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
        } else {
          _dateTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.gris.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.violet.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.filter_list, color: AppColors.violet, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                l.filterLabel,
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _reset,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.violetClair.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l.resetFilters,
                    style: GoogleFonts.dmSans(
                      color: AppColors.violetClair,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Status chips
          Text(
            l.statusLabel,
            style: TextStyle(
              color: AppColors.gris,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusOptions(l).map((option) {
              final (value, label, color) = option;
              final isActive = _statuses.contains(value);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (isActive) {
                      _statuses.remove(value);
                    } else {
                      _statuses.add(value);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? color.withAlpha(30) : AppColors.fond,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? color : AppColors.border,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isActive ? color : AppColors.gris,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Date range
          Text(
            l.periodLabel,
            style: TextStyle(
              color: AppColors.gris,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _DatePickerButton(
                  label: l.dateFrom,
                  date: _dateFrom,
                  onTap: () => _pickDate(isFrom: true),
                  onClear: () => setState(() => _dateFrom = null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerButton(
                  label: l.dateTo,
                  date: _dateTo,
                  onTap: () => _pickDate(isFrom: false),
                  onClear: () => setState(() => _dateTo = null),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Pro name search
          Text(
            l.professionalLabel,
            style: TextStyle(
              color: AppColors.gris,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _proNameController,
            style: TextStyle(color: AppColors.blanc, fontSize: 14),
            decoration: InputDecoration(
              hintText: l.searchProHint,
              hintStyle: TextStyle(color: AppColors.gris.withAlpha(150)),
              prefixIcon: Icon(
                Icons.search,
                color: AppColors.gris,
                size: 18,
              ),
              filled: true,
              fillColor: AppColors.fond,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.violet),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Apply button
          GestureDetector(
            onTap: _apply,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.gradientAccent,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.primaryButtonShadow,
              ),
              child: Center(
                child: Text(
                  l.applyTheFilters,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

// ─── Date picker button ─────────────────────────────────────────────────────

class _DatePickerButton extends StatelessWidget {
  const _DatePickerButton({
    required this.label,
    this.date,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.fond,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? AppColors.violet : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: date != null ? AppColors.violet : AppColors.gris,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null
                    ? '${date!.day}/${date!.month.toString().padLeft(2, '0')}/${date!.year}'
                    : label,
                style: TextStyle(
                  color: date != null ? AppColors.blanc : AppColors.gris,
                  fontSize: 13,
                ),
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.gris,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
