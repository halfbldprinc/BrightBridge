import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class MyTextArea extends StatefulWidget {
  final String label;
  final bool isPassword;
  final bool isNumber;
  final bool isDropdown;
  final bool isRadioButton; // Added radio button flag
  final List<String>? options; // List of options for radio buttons
  final bool isDateTime;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const MyTextArea({
    super.key,
    required this.label,
    required this.controller,
    this.isPassword = false,
    this.keyboardType,
    this.isNumber = false,
    this.isDropdown = false,
    this.isRadioButton = false, // Default to false
    this.options,
    this.isDateTime = false,
  });

  @override
  MyTextAreaState createState() => MyTextAreaState();
}

class MyTextAreaState extends State<MyTextArea> {
  // For radio buttons: Store the selected value
  String _selectedRadio = "";

  List<TextInputFormatter> get _inputFormatters => widget.isNumber
      ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
      : <TextInputFormatter>[];

  InputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: color),
      );

  Widget _buildDropdown() {
    if (widget.options == null || widget.options!.isEmpty) {
      return const Text("No options available",
          style: TextStyle(color: Colors.white));
    }
    final dropdownItems = widget.options!
        .map((option) => DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
            ))
        .toList();

    return DropdownButtonFormField<String>(
      dropdownColor: Colors.grey[900],
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.black,
        labelText: widget.label,
        labelStyle: const TextStyle(
          color: Colors.tealAccent,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: _border(Colors.grey[700]!),
        focusedBorder: _border(Colors.tealAccent),
      ),
      items: dropdownItems,
      onChanged: (value) {
        widget.controller.text = value ?? '';
      },
    );
  }

  Widget _buildDateTimePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final DateFormat formatter = DateFormat('yyyy-MM-dd');
        DateTime? selectedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: Colors.tealAccent,
                  onPrimary: Colors.black,
                  surface: Colors.grey,
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: Colors.grey[800],
              ),
              child: child!,
            );
          },
        );

        if (selectedDate != null) {
          widget.controller.text = formatter.format(selectedDate);
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: widget.controller,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.black,
            labelText: widget.label,
            labelStyle: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            suffixIcon: const Icon(
              Icons.calendar_today_outlined,
              color: Colors.tealAccent,
            ),
            enabledBorder: _border(Colors.grey[700]!),
            focusedBorder: _border(Colors.tealAccent),
          ),
        ),
      ),
    );
  }

  // Radio button widget - dynamically built
  Widget _buildRadioButton() {
    if (widget.options == null || widget.options!.isEmpty) {
      return const Text("No options available",
          style: TextStyle(color: Colors.white));
    }

    List<Widget> radioButtons = [];
    for (int i = 0; i < widget.options!.length; i++) {
      radioButtons.add(
        Row(
          children: [
            Radio<String>(
              value: widget.options![i],
              groupValue: _selectedRadio,
              onChanged: (value) {
                setState(() {
                  _selectedRadio = value!;
                  widget.controller.text =
                      value; // Update the controller with the selected value
                });
              },
              activeColor: Colors.tealAccent,
            ),
            Text(
              widget.options![i],
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return Column(children: radioButtons);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
      child: widget.isRadioButton
          ? _buildRadioButton() // Show radio button if isRadioButton is true
          : widget.isDropdown
              ? _buildDropdown()
              : widget.isDateTime
                  ? _buildDateTimePicker(context)
                  : TextFormField(
                      obscureText: widget.isPassword,
                      controller: widget.controller,
                      keyboardType: widget.keyboardType,
                      inputFormatters: _inputFormatters,
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.black,
                        labelText: widget.label,
                        labelStyle: const TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        enabledBorder: _border(Colors.grey[700]!),
                        focusedBorder: _border(Colors.tealAccent),
                      ),
                    ),
    );
  }
}
