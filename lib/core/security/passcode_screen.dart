import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'security_service.dart';

enum PasscodeMode { unlock, setup }

class PasscodeScreen extends StatefulWidget {
  final PasscodeMode mode;
  final VoidCallback onSuccess;

  const PasscodeScreen({
    super.key,
    required this.mode,
    required this.onSuccess,
  });

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  final SecurityService _securityService = SecurityService();
  String _enteredPin = '';
  String? _firstPin;
  String _message = "Enter Passcode";
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (widget.mode == PasscodeMode.setup) {
      _message = "Enter New 4-Digit Passcode";
    }
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length >= 4) return;
    HapticFeedback.lightImpact();
    setState(() {
      _hasError = false;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      _processPin();
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _hasError = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _processPin() async {
    if (widget.mode == PasscodeMode.setup) {
      if (_firstPin == null) {
        setState(() {
          _firstPin = _enteredPin;
          _enteredPin = '';
          _message = "Confirm Your Passcode";
        });
      } else {
        if (_enteredPin == _firstPin) {
          await _securityService.setPasscode(_enteredPin);
          widget.onSuccess();
        } else {
          HapticFeedback.heavyImpact();
          setState(() {
            _hasError = true;
            _enteredPin = '';
            _firstPin = null;
            _message = "Passcodes didn't match. Try again.";
          });
        }
      }
    } else {
      final isValid = await _securityService.verifyPasscode(_enteredPin);
      if (isValid) {
        HapticFeedback.mediumImpact();
        widget.onSuccess();
      } else {
        HapticFeedback.heavyImpact();
        setState(() {
          _hasError = true;
          _enteredPin = '';
          _message = "Incorrect Passcode";
        });
      }
    }
  }

  Future<void> _triggerBiometrics() async {
    final success = await _securityService.authenticateWithBiometrics();
    if (success) {
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Icon(Icons.lock_rounded, size: 48, color: AppColors.accentGold),
            const SizedBox(height: 16),
            Text(
              _message,
              style: AppTypography.headingSmall.copyWith(
                color: _hasError ? AppColors.tagCoral : null,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // 4 Pin dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? (_hasError ? AppColors.tagCoral : AppColors.accentGold)
                        : Colors.transparent,
                    border: Border.all(
                      color: _hasError
                          ? AppColors.tagCoral
                          : (isFilled ? AppColors.accentGold : Colors.grey),
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            const Spacer(),
            // Numeric Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3'], isDark),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['4', '5', '6'], isDark),
                  const SizedBox(height: 16),
                  _buildKeypadRow(['7', '8', '9'], isDark),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.fingerprint_rounded, size: 32),
                        color: AppColors.accentGold,
                        onPressed: _triggerBiometrics,
                      ),
                      _KeypadButton(digit: '0', isDark: isDark, onTap: () => _onKeyPress('0')),
                      IconButton(
                        icon: const Icon(Icons.backspace_outlined, size: 28),
                        onPressed: _onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) {
        return _KeypadButton(digit: d, isDark: isDark, onTap: () => _onKeyPress(d));
      }).toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String digit;
  final bool isDark;
  final VoidCallback onTap;

  const _KeypadButton({
    required this.digit,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: AppTypography.headingLarge.copyWith(fontSize: 28),
        ),
      ),
    );
  }
}

