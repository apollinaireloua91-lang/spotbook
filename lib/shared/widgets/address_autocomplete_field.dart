import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_colors.dart';

class AddressAutocompleteField extends StatefulWidget {
  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.fillColor,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final Color? fillColor;

  @override
  State<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  List<_PlacePrediction> _predictions = [];
  bool _isLoading = false;
  Timer? _debounce;

  static const _apiKey = String.fromEnvironment('GOOGLE_PLACES_KEY');

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      setState(() => _predictions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchPredictions(query);
    });
  }

  Future<void> _fetchPredictions(String query) async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {'input': query, 'key': _apiKey},
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final predictions = (data['predictions'] as List?) ?? [];
        setState(() {
          _predictions = predictions
              .map((p) => _PlacePrediction(
                    primary: (p['structured_formatting']
                            ?['main_text'] as String?) ??
                        '',
                    secondary: (p['structured_formatting']
                            ?['secondary_text'] as String?) ??
                        '',
                    full: (p['description'] as String?) ?? '',
                  ))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching places: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          style: const TextStyle(color: AppColors.blanc),
          onChanged: _onQueryChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.icon != null
                ? Icon(widget.icon, color: AppColors.gris)
                : null,
            fillColor: widget.fillColor,
            filled: widget.fillColor != null ? true : null,
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        if (_predictions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _predictions.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  title: Text(prediction.primary,
                      style: const TextStyle(color: AppColors.blanc)),
                  subtitle: Text(prediction.secondary,
                      style: const TextStyle(
                          color: AppColors.gris, fontSize: 12)),
                  onTap: () {
                    widget.controller.text = prediction.full;
                    setState(() => _predictions = []);
                    FocusScope.of(context).unfocus();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PlacePrediction {
  const _PlacePrediction({
    required this.primary,
    required this.secondary,
    required this.full,
  });

  final String primary;
  final String secondary;
  final String full;
}
