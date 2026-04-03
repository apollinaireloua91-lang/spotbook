import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_colors.dart';

/// Structured result from Google Place Details.
class PlaceDetails {
  const PlaceDetails({
    required this.address,
    required this.city,
    this.province,
    this.postalCode,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final String city;
  final String? province;
  final String? postalCode;
  final double latitude;
  final double longitude;
}

class AddressAutocompleteField extends StatefulWidget {
  const AddressAutocompleteField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.fillColor,
    this.onPlaceSelected,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final Color? fillColor;

  /// Called when a user taps a suggestion and Place Details are resolved.
  final ValueChanged<PlaceDetails>? onPlaceSelected;

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
        {'input': query, 'key': _apiKey, 'types': 'address'},
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
                    placeId: (p['place_id'] as String?) ?? '',
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

  Future<void> _selectPlace(_PlacePrediction prediction) async {
    widget.controller.text = prediction.full;
    setState(() => _predictions = []);
    FocusScope.of(context).unfocus();

    if (prediction.placeId.isEmpty || widget.onPlaceSelected == null) return;

    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/details/json',
        {
          'place_id': prediction.placeId,
          'fields': 'address_components,geometry',
          'key': _apiKey,
        },
      );
      final response = await http.get(uri);
      if (response.statusCode != 200) return;

      final result =
          (json.decode(response.body) as Map<String, dynamic>)['result']
              as Map<String, dynamic>?;
      if (result == null) return;

      final components =
          (result['address_components'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final geometry = result['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;

      String city = '';
      String? province;
      String? postalCode;

      for (final c in components) {
        final types = (c['types'] as List).cast<String>();
        if (types.contains('locality')) {
          city = c['long_name'] as String? ?? '';
        } else if (types.contains('administrative_area_level_1')) {
          province = c['long_name'] as String?;
        } else if (types.contains('postal_code')) {
          postalCode = c['long_name'] as String?;
        }
      }

      final lat = (location?['lat'] as num?)?.toDouble();
      final lng = (location?['lng'] as num?)?.toDouble();

      if (lat != null && lng != null) {
        widget.onPlaceSelected!(PlaceDetails(
          address: prediction.full,
          city: city,
          province: province,
          postalCode: postalCode,
          latitude: lat,
          longitude: lng,
        ));
      }
    } catch (e) {
      debugPrint('Error fetching place details: $e');
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
            labelStyle: const TextStyle(color: AppColors.gris),
            hintStyle: TextStyle(color: AppColors.gris.withAlpha(128)),
            prefixIcon: widget.icon != null
                ? Icon(widget.icon, color: AppColors.gris, size: 20)
                : null,
            fillColor: widget.fillColor,
            filled: widget.fillColor != null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
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
                  leading: const Icon(Icons.location_on_outlined,
                      color: AppColors.gris, size: 20),
                  title: Text(prediction.primary,
                      style: const TextStyle(color: AppColors.blanc)),
                  subtitle: Text(prediction.secondary,
                      style: const TextStyle(
                          color: AppColors.gris, fontSize: 12)),
                  onTap: () => _selectPlace(prediction),
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
    required this.placeId,
  });

  final String primary;
  final String secondary;
  final String full;
  final String placeId;
}
