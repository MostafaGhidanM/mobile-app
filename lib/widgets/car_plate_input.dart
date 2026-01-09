import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CarPlateInput extends StatefulWidget {
  final String? value;
  final ValueChanged<String> onChanged;
  final String? label;
  final bool required;

  const CarPlateInput({
    Key? key,
    this.value,
    required this.onChanged,
    this.label,
    this.required = false,
  }) : super(key: key);

  @override
  State<CarPlateInput> createState() => _CarPlateInputState();
}

class _CarPlateInputState extends State<CarPlateInput> {
  final List<TextEditingController> _controllers = List.generate(
    8,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    8,
    (_) => FocusNode(),
  );

  // Example plate: "ط ف ل 6 3 5 4" - when entered from right to left
  // Displayed left to right in squares: ['', '4', '5', '3', '6', 'ل', 'ف', 'ط']
  // Index 0 is leftmost (empty), index 7 is rightmost (ط)
  final List<String> _examplePlate = ['', '4', '5', '3', '6', 'ل', 'ف', 'ط'];

  @override
  void initState() {
    super.initState();
    _initializeFromValue();
    _setupFocusListeners();
  }

  void _initializeFromValue() {
    if (widget.value != null && widget.value!.isNotEmpty) {
      final chars = widget.value!.split('').where((c) => c.trim().isNotEmpty).toList();
      final newSquares = List<String>.filled(8, '');
      // Fill from right to left (index 7 is rightmost, index 0 is leftmost)
      chars.asMap().forEach((i, char) {
        if (i < 7) {
          // Only fill 7 squares, leave index 0 empty
          newSquares[7 - i] = char;
        }
      });
      for (int i = 0; i < 8; i++) {
        _controllers[i].text = newSquares[i];
      }
    }
  }

  void _setupFocusListeners() {
    for (int i = 0; i < 8; i++) {
      _focusNodes[i].addListener(() {
        if (!_focusNodes[i].hasFocus) {
          // When losing focus, ensure the value is updated
          _updateValue();
        }
      });
    }
  }

  @override
  void didUpdateWidget(CarPlateInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _initializeFromValue();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _updateValue() {
    // Build value from right to left (index 7 to 1, skip index 0)
    final reversedSquares = List<String>.from(_controllers.map((c) => c.text)).reversed.toList();
    final filtered = reversedSquares.asMap().entries
        .where((entry) => entry.key != 7 && entry.value.trim().isNotEmpty)
        .map((entry) => entry.value)
        .toList();
    final plateValue = filtered.join('').trim();
    widget.onChanged(plateValue);
  }

  void _handleInput(int index, String inputValue) {
    // Get the actual character entered (handle paste or single character)
    String char = inputValue;
    if (inputValue.length > 1) {
      // If multiple characters (paste), take the last one
      char = inputValue[inputValue.length - 1];
    }

    // Filter allowed characters (Arabic letters, numbers, space)
    final allowedPattern = RegExp(r'[\u0600-\u06FF0-9\s]');
    if (char.isNotEmpty && !allowedPattern.hasMatch(char)) {
      return;
    }

    // If user typed in a square that's not the rightmost empty one, find the rightmost empty square
    // Always skip index 0 (leftmost) to keep it empty
    int targetIndex = index;
    if (char.isNotEmpty) {
      // Find rightmost empty square (skip index 0)
      for (int i = 7; i >= 1; i--) {
        if (_controllers[i].text.isEmpty) {
          targetIndex = i;
          break;
        }
      }
    }

    _controllers[targetIndex].text = char;
    _updateValue();

    // Auto-move to next square (left) if character entered and not at index 1 (skip index 0)
    if (char.isNotEmpty && targetIndex > 1) {
      // Find next empty square to the left (skip index 0)
      for (int i = targetIndex - 1; i >= 1; i--) {
        if (_controllers[i].text.isEmpty) {
          Future.microtask(() => _focusNodes[i].requestFocus());
          return;
        }
      }
    }
  }

  void _handleKeyDown(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isNotEmpty) {
          // Clear current square
          _controllers[index].clear();
          _updateValue();
        } else if (index < 7 && index > 0) {
          // Move to next square (right) when backspacing empty square (skip index 0)
          _focusNodes[index + 1].requestFocus();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft && index < 7) {
        // Arrow left moves to right (next square)
        _focusNodes[index + 1].requestFocus();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight && index > 1) {
        // Arrow right moves to left (previous square, but skip index 0)
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  void _handlePaste(String pastedText) {
    final chars = pastedText.substring(0, pastedText.length > 8 ? 8 : pastedText.length).split('');
    final newSquares = List<String>.filled(8, '');
    // Fill from right to left
    chars.asMap().forEach((i, char) {
      if (i < 8 && RegExp(r'[\u0600-\u06FF0-9\s]').hasMatch(char)) {
        newSquares[7 - i] = char;
      }
    });
    for (int i = 0; i < 8; i++) {
      _controllers[i].text = newSquares[i];
    }
    _updateValue();
    // Focus on rightmost empty square after paste (skip index 0)
    for (int i = 7; i >= 1; i--) {
      if (newSquares[i].isEmpty) {
        _focusNodes[i].requestFocus();
        break;
      }
    }
  }

  bool get _allEmpty {
    return _controllers.every((controller) => controller.text.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final isRTL = Localizations.localeOf(context).languageCode == 'ar';
    final instructionText = isRTL
        ? 'أدخل رقم اللوحة من اليمين إلى اليسار (مثال: ط ف ل 6 3 5 4)'
        : 'Enter plate number from right to left (e.g., ط ف ل 6 3 5 4)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${widget.label}${widget.required ? ' *' : ''}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List.generate(8, (index) {
            return Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 8),
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                textAlign: TextAlign.center,
                maxLength: 1,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _controllers[index].text.isNotEmpty ? Colors.black : Colors.grey[600],
                ),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  hintText: _allEmpty ? _examplePlate[index] : '',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 18,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) => _handleInput(index, value),
                onTap: () {
                  // Allow user to click and type in any square
                  // The handleInput will redirect the character to the rightmost empty square
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\u0600-\u06FF0-9\s]')),
                ],
                keyboardType: TextInputType.text,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          instructionText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: isRTL ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }
}

