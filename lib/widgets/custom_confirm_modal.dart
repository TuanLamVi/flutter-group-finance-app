import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

/// Kiểu Modal
enum ConfirmType { success, warning, error, info }

/// Custom Confirm Modal
class CustomConfirmModal {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String? positiveText,
    String? negativeText,
    ConfirmType type = ConfirmType.info,
    bool barrierDismissible = false,
    VoidCallback? onPositive,
    VoidCallback? onNegative,
    Widget? customContent,
    bool showTextInput = false,
    String? textInputHint,
    TextEditingController? textInputController,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _ConfirmModalWidget(
        title: title,
        message: message,
        positiveText: positiveText,
        negativeText: negativeText,
        type: type,
        onPositive: onPositive,
        onNegative: onNegative,
        customContent: customContent,
        showTextInput: showTextInput,
        textInputHint: textInputHint,
        textInputController: textInputController,
      ),
    );
  }
}

class _ConfirmModalWidget extends StatefulWidget {
  final String title;
  final String message;
  final String? positiveText;
  final String? negativeText;
  final ConfirmType type;
  final VoidCallback? onPositive;
  final VoidCallback? onNegative;
  final Widget? customContent;
  final bool showTextInput;
  final String? textInputHint;
  final TextEditingController? textInputController;

  const _ConfirmModalWidget({
    required this.title,
    required this.message,
    this.positiveText,
    this.negativeText,
    required this.type,
    this.onPositive,
    this.onNegative,
    this.customContent,
    this.showTextInput = false,
    this.textInputHint,
    this.textInputController,
  });

  @override
  State<_ConfirmModalWidget> createState() => _ConfirmModalWidgetState();
}

class _ConfirmModalWidgetState extends State<_ConfirmModalWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getColorByType() {
    switch (widget.type) {
      case ConfirmType.success:
        return AppTheme.successColor;
      case ConfirmType.warning:
        return AppTheme.warningColor;
      case ConfirmType.error:
        return AppTheme.errorColor;
      case ConfirmType.info:
        return AppTheme.infoColor;
    }
  }

  IconData _getIconByType() {
    switch (widget.type) {
      case ConfirmType.success:
        return Icons.check_circle_rounded;
      case ConfirmType.warning:
        return Icons.warning_rounded;
      case ConfirmType.error:
        return Icons.error_rounded;
      case ConfirmType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with background
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _getColorByType().withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconByType(),
                        color: _getColorByType(),
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.lightTextColor,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Message
                    Text(
                      widget.message,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.lightHintColor,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Custom Content (if any)
                    if (widget.customContent != null) ...[
                      widget.customContent!,
                      const SizedBox(height: 20),
                    ],

                    // Text Input (if needed)
                    if (widget.showTextInput) ...[
                      TextFormField(
                        controller: widget.textInputController,
                        decoration: InputDecoration(
                          hintText: widget.textInputHint ?? 'Nhập thông tin',
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                        minLines: 2,
                        keyboardType: TextInputType.multiline,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Buttons
                    Row(
                      children: [
                        // Negative Button
                        if (widget.negativeText != null)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                widget.onNegative?.call();
                                Navigator.of(context).pop(false);
                              },
                              child: Text(widget.negativeText!),
                            ),
                          ),
                        if (widget.negativeText != null) const SizedBox(width: 12),

                        // Positive Button
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getColorByType(),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              widget.onPositive?.call();
                              Navigator.of(context).pop(true);
                            },
                            child: Text(widget.positiveText ?? 'Đồng ý'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      ),
    );
  }
}

/// Helper Modal classes
class SuccessModal {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String positiveText = 'OK',
  }) =>
      CustomConfirmModal.show(
        context,
        title: title,
        message: message,
        positiveText: positiveText,
        type: ConfirmType.success,
        negativeText: null,
        barrierDismissible: true,
      );
}

class WarningModal {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String positiveText = 'Đồng ý',
    String negativeText = 'Hủy',
  }) =>
      CustomConfirmModal.show(
        context,
        title: title,
        message: message,
        positiveText: positiveText,
        negativeText: negativeText,
        type: ConfirmType.warning,
      );
}

class ErrorModal {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String positiveText = 'OK',
  }) =>
      CustomConfirmModal.show(
        context,
        title: title,
        message: message,
        positiveText: positiveText,
        type: ConfirmType.error,
        negativeText: null,
        barrierDismissible: true,
      );
}

class InfoModal {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String positiveText = 'OK',
    String? negativeText,
  }) =>
      CustomConfirmModal.show(
        context,
        title: title,
        message: message,
        positiveText: positiveText,
        negativeText: negativeText,
        type: ConfirmType.info,
      );
}
