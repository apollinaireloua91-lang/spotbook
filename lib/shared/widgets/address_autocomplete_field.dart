import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
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
  State<AddressAutocompleteField> createState() => _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<AddressAutocompleteField> {
  late final FlutterGooglePlacesSdk _places;
  List<AutocompletePrediction> _predictions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    const apiKey = String.fromEnvironment('GOOGLE_PLACES_KEY');
    _places = FlutterGooglePlacesSdk(apiKey);
  }

  Future<void> _fetchPredictions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _places.findAutocompletePredictions(query);
      setState(() {
        _predictions = response.predictions;
      });
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
          onChanged: _fetchPredictions,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: widget.icon != null ? Icon(widget.icon, color: AppColors.gris) : null,
            fillColor: widget.fillColor,
            filled: widget.fillColor != null ? true : null,
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
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
              separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  title: Text(prediction.primaryText, style: const TextStyle(color: AppColors.blanc)),
                  subtitle: Text(prediction.secondaryText, style: const TextStyle(color: AppColors.gris, fontSize: 12)),
                  onTap: () {
                    widget.controller.text = prediction.fullText;
                    setState(() {
                      _predictions = [];
                    });
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
