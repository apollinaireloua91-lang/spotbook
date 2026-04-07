import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../data/event_notifier.dart';
import '../../data/event_repository.dart';

// ═════════════════════════════════════════════════════════════════════════════
// STATE
// ═════════════════════════════════════════════════════════════════════════════

class _CreateState {
  const _CreateState({this.isCreating = false, this.ticketTypes = const []});
  final bool isCreating;
  final List<_TicketInput> ticketTypes;
  _CreateState copyWith({bool? isCreating, List<_TicketInput>? ticketTypes}) =>
      _CreateState(
        isCreating: isCreating ?? this.isCreating,
        ticketTypes: ticketTypes ?? this.ticketTypes,
      );
}

class _TicketInput {
  String name = '';
  double price = 0;
  int quantity = 0;
}

class _CreateNotifier extends Notifier<_CreateState> {
  @override
  _CreateState build() => const _CreateState();

  void addTicketType() {
    if (state.ticketTypes.length >= 5) return;
    state = state.copyWith(
        ticketTypes: [...state.ticketTypes, _TicketInput()]);
  }

  void removeTicketType(int index) {
    final list = [...state.ticketTypes]..removeAt(index);
    state = state.copyWith(ticketTypes: list);
  }

  void updateTicketType(int index,
      {String? name, double? price, int? quantity}) {
    final list = [...state.ticketTypes];
    if (name != null) list[index].name = name;
    if (price != null) list[index].price = price;
    if (quantity != null) list[index].quantity = quantity;
    state = state.copyWith(ticketTypes: list);
  }

  Future<void> create({
    required String title,
    required String description,
    required DateTime date,
    required TimeOfDay startTime,
    required String location,
    String? address,
    XFile? coverImage,
  }) async {
    state = state.copyWith(isCreating: true);
    try {
      final repo = ref.read(eventRepositoryProvider);

      int totalCapacity = 0;
      for (final t in state.ticketTypes) {
        if (t.name.isNotEmpty && t.quantity > 0) {
          totalCapacity += t.quantity;
        }
      }

      final event = await repo.createEvent(
        title: title,
        description: description,
        eventDate: date,
        startTime: startTime,
        location: location,
        address: address,
        totalCapacity: totalCapacity,
      );

      if (coverImage != null) {
        final bytes = await coverImage.readAsBytes();
        await repo.uploadCover(event.id, bytes);
      }

      for (final t in state.ticketTypes) {
        if (t.name.isNotEmpty && t.quantity > 0) {
          await repo.addTicketType(
            eventId: event.id,
            name: t.name,
            price: t.price,
            quantity: t.quantity,
          );
        }
      }

      ref.invalidate(eventsProvider);
      state = state.copyWith(isCreating: false);
    } catch (_) {
      state = state.copyWith(isCreating: false);
      rethrow;
    }
  }
}

final _createProvider = NotifierProvider<_CreateNotifier, _CreateState>(
  _CreateNotifier.new,
  isAutoDispose: true,
);

// ═════════════════════════════════════════════════════════════════════════════
// SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  XFile? _coverImage;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Pickers ──

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.violet,
            onPrimary: AppColors.textOnPrimary,
            surface: AppColors.fond,
            onSurface: AppColors.blanc,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppColors.violet,
            onPrimary: AppColors.textOnPrimary,
            surface: AppColors.fond,
            onSurface: AppColors.blanc,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _pickCover() async {
    final image = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (image != null) setState(() => _coverImage = image);
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final location = _locationCtrl.text.trim();

    if (title.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and location are required'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    try {
      await ref.read(_createProvider.notifier).create(
            title: title,
            description: _descCtrl.text.trim(),
            date: _selectedDate,
            startTime: _selectedTime,
            location: location,
            address: _addressCtrl.text.trim().isEmpty
                ? null
                : _addressCtrl.text.trim(),
            coverImage: _coverImage,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final min = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_createProvider);
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: CustomScrollView(
        slivers: [
          // ── App bar ──
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.fond,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: Semantics(
              label: 'Back',
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 0.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: AppColors.blanc, size: 16),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.pop();
                },
              ),
            ),
            title: Text(
              'Create Event',
              style: GoogleFonts.sora(
                color: AppColors.blanc,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            centerTitle: true,
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.dmSans(
                    color: AppColors.gris,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 32 + bottomPad),
            sliver: SliverList.list(
              children: [
                // ════════════════════════════════════════════════════════
                // SECTION 1 — Cover Image
                // ════════════════════════════════════════════════════════
                _SectionHeader(
                  title: 'Cover Image',
                  subtitle: 'This is the first thing attendees will see',
                ),
                const SizedBox(height: 14),
                _CoverImagePicker(
                  coverImage: _coverImage,
                  onTap: _pickCover,
                ),
                const SizedBox(height: 32),

                // ════════════════════════════════════════════════════════
                // SECTION 2 — Event Details
                // ════════════════════════════════════════════════════════
                _SectionHeader(
                  title: 'Event Details',
                  subtitle: 'Name your event and tell people what it\'s about',
                ),
                const SizedBox(height: 14),
                _PremiumField(
                  controller: _titleCtrl,
                  label: 'Event Title',
                  hint: 'e.g. Summer Jazz Workshop',
                  icon: Icons.celebration_outlined,
                  isRequired: true,
                ),
                const SizedBox(height: 12),
                _PremiumField(
                  controller: _descCtrl,
                  label: 'Description',
                  hint: 'Describe the agenda, what attendees will learn, etc.',
                  icon: Icons.notes_outlined,
                  maxLines: 4,
                ),
                const SizedBox(height: 32),

                // ════════════════════════════════════════════════════════
                // SECTION 3 — Date & Time
                // ════════════════════════════════════════════════════════
                _SectionHeader(
                  title: 'When?',
                  subtitle: 'Set the date and start time',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _DateTimeTile(
                        icon: Icons.calendar_today_outlined,
                        label: DateFormat('EEE, MMM d').format(_selectedDate),
                        sublabel: DateFormat('yyyy').format(_selectedDate),
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _DateTimeTile(
                        icon: Icons.access_time_outlined,
                        label: _formatTime(_selectedTime),
                        sublabel: 'Start time',
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ════════════════════════════════════════════════════════
                // SECTION 4 — Location
                // ════════════════════════════════════════════════════════
                _SectionHeader(
                  title: 'Where?',
                  subtitle: 'Let guests know the location and time details',
                ),
                const SizedBox(height: 14),
                _PremiumField(
                  controller: _locationCtrl,
                  label: 'Venue Name',
                  hint: 'e.g. Grand Convention Center',
                  icon: Icons.location_on_outlined,
                  isRequired: true,
                ),
                const SizedBox(height: 12),
                _PremiumField(
                  controller: _addressCtrl,
                  label: 'Address',
                  hint: 'Search for location',
                  icon: Icons.pin_drop_outlined,
                ),
                const SizedBox(height: 32),

                // ════════════════════════════════════════════════════════
                // SECTION 5 — Tickets
                // ════════════════════════════════════════════════════════
                _SectionHeader(
                  title: 'Tickets & Pricing',
                  subtitle:
                      'Define your ticket types, pricing, and availability',
                  trailing: s.ticketTypes.length < 5
                      ? GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(_createProvider.notifier)
                                .addTicketType();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.violet.withAlpha(15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppColors.violet.withAlpha(40)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add,
                                    color: AppColors.violet, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'Add',
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.violet,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 14),

                if (s.ticketTypes.isEmpty)
                  _EmptyTicketsPlaceholder(
                    onAdd: () {
                      HapticFeedback.lightImpact();
                      ref.read(_createProvider.notifier).addTicketType();
                    },
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: s.ticketTypes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _TicketTypeCard(
                        index: index,
                        onRemove: () => ref
                            .read(_createProvider.notifier)
                            .removeTicketType(index),
                        onUpdate: (name, price, qty) => ref
                            .read(_createProvider.notifier)
                            .updateTicketType(index,
                                name: name, price: price, quantity: qty),
                      );
                    },
                  ),
                const SizedBox(height: 40),

                // ════════════════════════════════════════════════════════
                // PUBLISH BUTTON
                // ════════════════════════════════════════════════════════
                _PublishButton(
                  isCreating: s.isCreating,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═════════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.sora(
                  color: AppColors.blanc,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.dmSans(
            color: AppColors.gris,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// COVER IMAGE PICKER
// ═════════════════════════════════════════════════════════════════════════════

class _CoverImagePicker extends StatelessWidget {
  const _CoverImagePicker({required this.coverImage, required this.onTap});

  final XFile? coverImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 200,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: coverImage == null
              ? Border.all(
                  color: AppColors.gris.withAlpha(60),
                  width: 1.5,
                  strokeAlign: BorderSide.strokeAlignInside,
                )
              : null,
          boxShadow: coverImage != null
              ? [
                  BoxShadow(
                    color: AppColors.shadowCard,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: coverImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(coverImage!.path), fit: BoxFit.cover),
                  // Gradient overlay bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withAlpha(120),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Edit badge
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit, size: 14, color: AppColors.blanc),
                          const SizedBox(width: 4),
                          Text(
                            'Change',
                            style: GoogleFonts.dmSans(
                              color: AppColors.blanc,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.violet.withAlpha(12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_photo_alternate_outlined,
                        color: AppColors.violet, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tap to upload cover',
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recommended: 1200 x 630px',
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PREMIUM FIELD
// ═════════════════════════════════════════════════════════════════════════════

class _PremiumField extends StatelessWidget {
  const _PremiumField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.isRequired = false,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: AppColors.blanc,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.dmSans(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              color: AppColors.gris.withAlpha(150),
              fontSize: 14,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(icon, color: AppColors.gris, size: 20),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 0),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.border, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: AppColors.violet, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DATE / TIME TILE
// ═════════════════════════════════════════════════════════════════════════════

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.violet.withAlpha(12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.violet, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      color: AppColors.blanc,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: GoogleFonts.dmSans(
                      color: AppColors.gris,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY TICKETS PLACEHOLDER
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyTicketsPlaceholder extends StatelessWidget {
  const _EmptyTicketsPlaceholder({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gris.withAlpha(40),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.violet.withAlpha(12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.confirmation_number_outlined,
                  color: AppColors.violet, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'No ticket types yet',
              style: GoogleFonts.dmSans(
                color: AppColors.blanc,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to add your first ticket tier',
              style: GoogleFonts.dmSans(
                color: AppColors.gris,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TICKET TYPE CARD
// ═════════════════════════════════════════════════════════════════════════════

class _TicketTypeCard extends StatelessWidget {
  const _TicketTypeCard({
    required this.index,
    required this.onRemove,
    required this.onUpdate,
  });

  final int index;
  final VoidCallback onRemove;
  final void Function(String? name, double? price, int? qty) onUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.violet.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.confirmation_number_outlined,
                    color: AppColors.violet, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Ticket Tier ${index + 1}',
                  style: GoogleFonts.sora(
                    color: AppColors.blanc,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Semantics(
                label: 'Remove ticket type',
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onRemove();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.delete_outline,
                        color: AppColors.error, size: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Ticket name
          _MiniField(
            label: 'TICKET NAME',
            hint: 'e.g. General Admission',
            onChanged: (v) => onUpdate(v, null, null),
          ),
          const SizedBox(height: 12),

          // Price + Quantity row
          Row(
            children: [
              Expanded(
                child: _MiniField(
                  label: 'PRICE',
                  hint: '\$ 0.00',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => onUpdate(null, double.tryParse(v), null),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniField(
                  label: 'QUANTITY',
                  hint: '0',
                  keyboardType: TextInputType.number,
                  onChanged: (v) => onUpdate(null, null, int.tryParse(v)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniField extends StatelessWidget {
  const _MiniField({
    required this.label,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
  });

  final String label;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColors.gris,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          style: GoogleFonts.dmSans(color: AppColors.blanc, fontSize: 14),
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              color: AppColors.gris.withAlpha(120),
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.violet, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PUBLISH BUTTON
// ═════════════════════════════════════════════════════════════════════════════

class _PublishButton extends StatelessWidget {
  const _PublishButton({required this.isCreating, required this.onPressed});

  final bool isCreating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCreating ? null : () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: isCreating ? null : AppColors.gradientAccent,
          color: isCreating ? AppColors.surfaceAlt : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isCreating
              ? null
              : [
                  BoxShadow(
                    color: AppColors.violet.withAlpha(40),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: isCreating
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: AppColors.gris,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Publish Event',
                      style: GoogleFonts.sora(
                        color: AppColors.textOnPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        color: AppColors.textOnPrimary, size: 20),
                  ],
                ),
        ),
      ),
    );
  }
}
