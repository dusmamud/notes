import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import 'security_service.dart';

enum PasscodeMode { unlockApp, unlockNote, setup }

class PasscodeScreen extends StatefulWidget {
  final PasscodeMode mode;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;
  final String? customTitle;

  const PasscodeScreen({
    super.key,
    required this.mode,
    required this.onSuccess,
    this.onCancel,
    this.customTitle,
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
  int _lockoutSeconds = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _initMode();
    _checkLockout();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _initMode() {
    if (widget.mode == PasscodeMode.setup) {
      _message = "Enter New 4-Digit Passcode";
    } else if (widget.mode == PasscodeMode.unlockNote) {
      _message = widget.customTitle ?? "Enter Passcode to Unlock Note";
      _tryAutoBiometric();
    } else {
      _message = widget.customTitle ?? "Enter Passcode to Unlock Notes";
      _tryAutoBiometric();
    }
  }

  Future<void> _checkLockout() async {
    final remaining = await _securityService.getRemainingLockoutSeconds();
    if (remaining > 0) {
      setState(() {
        _lockoutSeconds = remaining;
        _hasError = true;
        _message = "Too many attempts. Try again in $_lockoutSeconds s";
      });
      _startLockoutCountdown();
    }
  }

  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutSeconds <= 1) {
        timer.cancel();
        setState(() {
          _lockoutSeconds = 0;
          _hasError = false;
          _message = widget.mode == PasscodeMode.setup ? "Enter New Passcode" : "Enter Passcode";
        });
      } else {
        setState(() {
          _lockoutSeconds--;
          _message = "Too many attempts. Try again in $_lockoutSeconds s";
        });
      }
    });
  }

  Future<void> _tryAutoBiometric() async {
    final canBio = await _securityService.isBiometricsAvailable();
    if (canBio && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        _triggerBiometrics();
      }
    }
  }

  void _onKeyPress(String digit) {
    if (_lockoutSeconds > 0) return;
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
    if (_lockoutSeconds > 0) return;
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
        final lockout = await _securityService.getRemainingLockoutSeconds();
        if (lockout > 0) {
          setState(() {
            _lockoutSeconds = lockout;
            _hasError = true;
            _enteredPin = '';
            _message = "Too many attempts. Try again in $_lockoutSeconds s";
          });
          _startLockoutCountdown();
        } else {
          setState(() {
            _hasError = true;
            _enteredPin = '';
            _message = "Incorrect Passcode";
          });
        }
      }
    }
  }

  Future<void> _triggerBiometrics() async {
    if (_lockoutSeconds > 0) return;
    final success = await _securityService.authenticateWithBiometrics(
      reason: widget.mode == PasscodeMode.unlockNote ? "Unlock Note" : "Unlock Notes",
    );
    if (success && mounted) {
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: widget.onCancel != null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.onCancel != null) {
          widget.onCancel!();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: widget.onCancel != null
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: widget.onCancel,
                      )
                    : const SizedBox(height: 48),
              ),
              const Spacer(),
              Icon(Icons.lock_rounded, size: 48, color: AppColors.accentGold),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _message,
                  style: AppTypography.headingSmall.copyWith(
                    color: _hasError ? AppColors.tagCoral : null,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              // 4 Pin dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
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
                          color: _lockoutSeconds > 0 ? Colors.grey : AppColors.accentGold,
                          onPressed: _lockoutSeconds > 0 ? null : _triggerBiometrics,
                        ),
                        _KeypadButton(
                          digit: '0',
                          isDark: isDark,
                          onTap: () => _onKeyPress('0'),
                          disabled: _lockoutSeconds > 0,
                        ),
                        IconButton(
                          icon: const Icon(Icons.backspace_outlined, size: 28),
                          onPressed: _lockoutSeconds > 0 ? null : _onDelete,
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
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) {
        return _KeypadButton(
          digit: d,
          isDark: isDark,
          onTap: () => _onKeyPress(d),
          disabled: _lockoutSeconds > 0,
        );
      }).toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String digit;
  final bool isDark;
  final VoidCallback onTap;
  final bool disabled;

  const _KeypadButton({
    required this.digit,
    required this.isDark,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
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
          style: AppTypography.headingLarge.copyWith(
            fontSize: 28,
            color: disabled ? Colors.grey : null,
          ),
        ),
      ),
    );
  }
}

