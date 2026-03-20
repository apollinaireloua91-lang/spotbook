import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/widgets/address_autocomplete_field.dart';
import '../../data/event_notifier.dart';
import '../../data/event_repository.dart';

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

  void updateTicketType(int index, {String? name, double? price, int? quantity}) {
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
    required String location,
    String? address,
    XFile? coverImage,
  }) async {
    state = state.copyWith(isCreating: true);
    try {
      final repo = ref.read(eventRepositoryProvider);
      final event = await repo.createEvent(
        title: title,
        description: description,
        eventDate: date,
        location: location,
        address: address,
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
  XFile? _coverImage;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      _selectedDate = date;
    }
  }

  Future<void> _pickCover() async {
    final image = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (image != null) {
      _coverImage = image;
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Titre et lieu requis'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    try {
      await ref.read(_createProvider.notifier).create(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            date: _selectedDate,
            location: _locationCtrl.text.trim(),
            address: _addressCtrl.text.trim(),
            coverImage: _coverImage,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(_createProvider);
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        backgroundColor: AppColors.fond,
        leading: Semantics(
          label: 'Retour',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.blanc, size: 20),
            onPressed: () {
              HapticFeedback.mediumImpact();
              context.pop();
            },
          ),
        ),
        title: const Text('Créer un événement',
            style: TextStyle(color: AppColors.blanc, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickCover,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, color: AppColors.gris, size: 40),
                    SizedBox(height: 8),
                    Text('Ajouter une couverture', style: TextStyle(color: AppColors.gris, fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildField(_titleCtrl, 'Titre de l\'événement', Icons.event),
            const SizedBox(height: 14),
            _buildField(_descCtrl, 'Description', Icons.description, maxLines: 3),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: AppColors.gris, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDate),
                      style: const TextStyle(color: AppColors.blanc, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            AddressAutocompleteField(
              controller: _locationCtrl,
              label: 'Lieu',
              icon: Icons.location_on_outlined,
              fillColor: AppColors.surface,
            ),
            const SizedBox(height: 14),
            AddressAutocompleteField(
              controller: _addressCtrl,
              label: 'Adresse (optionnel)',
              icon: Icons.pin_drop_outlined,
              fillColor: AppColors.surface,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Types de billets',
                    style: TextStyle(color: AppColors.blanc, fontSize: 16, fontWeight: FontWeight.w600)),
                if (s.ticketTypes.length < 5)
                  Semantics(
                    label: 'Ajouter type billet',
                    child: IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.blanc),
                      onPressed: () => ref.read(_createProvider.notifier).addTicketType(),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: s.ticketTypes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _TicketTypeRow(
                  index: index,
                  onRemove: () => ref.read(_createProvider.notifier).removeTicketType(index),
                  onUpdate: (name, price, qty) => ref
                      .read(_createProvider.notifier)
                      .updateTicketType(index, name: name, price: price, quantity: qty),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: s.isCreating ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blanc,
                  foregroundColor: AppColors.fond,
                  disabledBackgroundColor: AppColors.surfaceAlt,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: s.isCreating
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.gris, strokeWidth: 2))
                    : const Text('Publier l\'événement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.blanc),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.gris),
        prefixIcon: Icon(icon, color: AppColors.gris, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

class _TicketTypeRow extends StatelessWidget {
  const _TicketTypeRow({required this.index, required this.onRemove, required this.onUpdate});
  final int index;
  final VoidCallback onRemove;
  final void Function(String? name, double? price, int? qty) onUpdate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              style: const TextStyle(color: AppColors.blanc, fontSize: 14),
              decoration: const InputDecoration(hintText: 'Nom', hintStyle: TextStyle(color: AppColors.gris, fontSize: 13), isDense: true, border: InputBorder.none),
              onChanged: (v) => onUpdate(v, null, null),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              style: const TextStyle(color: AppColors.blanc, fontSize: 14),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Prix', hintStyle: TextStyle(color: AppColors.gris, fontSize: 13), isDense: true, border: InputBorder.none),
              onChanged: (v) => onUpdate(null, double.tryParse(v), null),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: TextField(
              style: const TextStyle(color: AppColors.blanc, fontSize: 14),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Qté', hintStyle: TextStyle(color: AppColors.gris, fontSize: 13), isDense: true, border: InputBorder.none),
              onChanged: (v) => onUpdate(null, null, int.tryParse(v)),
            ),
          ),
          Semantics(
            label: 'Supprimer type billet',
            child: IconButton(
              icon: const Icon(Icons.close, color: AppColors.gris, size: 18),
              onPressed: onRemove,
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            ),
          ),
        ],
      ),
    );
  }
}
