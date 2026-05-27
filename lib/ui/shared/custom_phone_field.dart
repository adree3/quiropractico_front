import 'package:flutter/material.dart';
import 'package:quiropractico_front/utils/country_data.dart';

class CustomPhoneField extends StatefulWidget {
  final String label;
  final String? initialValue;
  final Function(String) onChanged;
  final String? Function(String?)? validator;

  const CustomPhoneField({
    Key? key,
    required this.label,
    this.initialValue,
    required this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  State<CustomPhoneField> createState() => _CustomPhoneFieldState();
}

class _CustomPhoneFieldState extends State<CustomPhoneField> {
  final GlobalKey<FormFieldState<String>> _fieldKey = GlobalKey<FormFieldState<String>>();
  late Country _selectedCountry;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  
  final FocusNode _countryFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    
    _selectedCountry = CountryData.countries.firstWhere(
      (c) => c.dialCode == '+34',
      orElse: () => CountryData.countries.first,
    );
    
    String initialNumber = '';
    
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      for (final country in CountryData.countries) {
        if (widget.initialValue!.startsWith(country.dialCode)) {
          _selectedCountry = country;
          initialNumber = widget.initialValue!.substring(country.dialCode.length);
          break;
        }
      }
      
      if (initialNumber.isEmpty) {
        initialNumber = widget.initialValue!;
      }
    }
    
    _phoneController = TextEditingController(text: initialNumber);
    // Formato inverso: [prefijo] [icono]
    _countryController = TextEditingController(
      text: '${_selectedCountry.dialCode} ${_selectedCountry.flag}',
    );

    void updateFocus() {
      setState(() {
        _isFocused = _countryFocusNode.hasFocus || _phoneFocusNode.hasFocus;
      });
    }

    _countryFocusNode.addListener(() {
      updateFocus();
      
      if (_countryFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && _countryFocusNode.hasFocus) {
            _countryController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _countryController.text.length,
            );
          }
        });
      } else {
        // Restauración en Blur con formato [prefijo] [icono]
        _countryController.text = '${_selectedCountry.flag} ${_selectedCountry.dialCode}';
      }
    });

    _phoneFocusNode.addListener(updateFocus);
  }

  @override
  void dispose() {
    _countryFocusNode.dispose();
    _phoneFocusNode.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _triggerOnChanged() {
    final concatenated = '${_selectedCountry.dialCode}${_phoneController.text.trim()}';
    _fieldKey.currentState?.didChange(concatenated);
    widget.onChanged(concatenated);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: _fieldKey,
      initialValue: '${_selectedCountry.dialCode}${_phoneController.text.trim()}',
      validator: (val) {
        if (widget.validator != null) {
          return widget.validator!(_phoneController.text);
        }
        return null;
      },
      builder: (FormFieldState<String> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            // Fake Border Container
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: field.hasError 
                      ? Colors.red.shade700 
                      : (_isFocused ? const Color(0xFF0EA5E9) : Colors.grey.shade300),
                  width: _isFocused ? 2.0 : 1.0, 
                ),
              ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Selector de País con Theme override para matar el padding del IconButton interno
                Theme(
                  data: Theme.of(context).copyWith(
                    iconButtonTheme: IconButtonThemeData(
                      style: IconButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        fixedSize: const Size(0, 0), // Fuerza a que el IconButton interno ocupe 0px
                      ),
                    ),
                  ),
                  child: DropdownMenu<Country>(
                    controller: _countryController,
                    focusNode: _countryFocusNode,
                    enableFilter: true,
                    requestFocusOnTap: true,
                    menuHeight: 250,
                    width: 85, 
                    trailingIcon: const SizedBox.shrink(), 
                    selectedTrailingIcon: const SizedBox.shrink(), 
                    inputDecorationTheme: const InputDecorationTheme(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      suffixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                    onSelected: (Country? country) {
                      if (country != null) {
                        setState(() {
                          _selectedCountry = country;
                        });
                        _countryController.text = '${country.dialCode} ${country.flag}';
                        _countryFocusNode.unfocus();
                        _triggerOnChanged();
                      }
                    },
                    dropdownMenuEntries: CountryData.countries.map<DropdownMenuEntry<Country>>(
                      (Country country) {
                        return DropdownMenuEntry<Country>(
                          value: country,
                          label: '${country.name} ${country.dialCode} ${country.flag}',
                          labelWidget: Text('${country.flag} ${country.dialCode}'),
                        );
                      },
                    ).toList(),
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                  indent: 8,
                  endIndent: 8,
                ),
                // Input para el Teléfono
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => _triggerOnChanged(),
                    decoration: InputDecoration(
                      hintText: 'Ej. 600 000 000',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (field.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Text(
              field.errorText!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
      },
    );
  }
}
