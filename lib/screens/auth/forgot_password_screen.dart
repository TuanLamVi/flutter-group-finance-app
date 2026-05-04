import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../main.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_normalizer.dart';
import '../../widgets/custom_toast.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late MaskTextInputFormatter _phoneMaskFormatter;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentStep = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _phoneMaskFormatter = MaskTextInputFormatter(
      mask: '(###) #### ####',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Validate Step 1: Phone & PIN
  Future<bool> _validateStep1() async {
    if (_phoneController.text.isEmpty) {
      CustomToast.show(context, 'Số điện thoại không được để trống', isError: true);
      return false;
    }

    if (!PhoneNormalizer.isValid(_phoneController.text)) {
      CustomToast.show(context, 'Số điện thoại không hợp lệ', isError: true);
      return false;
    }

    if (_pinController.text.isEmpty) {
      CustomToast.show(context, 'Mã PIN không được để trống', isError: true);
      return false;
    }

    if (!RegExp(r'^\d{4,6}$').hasMatch(_pinController.text)) {
      CustomToast.show(context, 'Mã PIN phải từ 4-6 chữ số', isError: true);
      return false;
    }

    setState(() => _isLoading = true);

    try {
      final firebaseService = getIt<FirebaseService>();
      final isValid = await firebaseService.verifyPhoneAndPin(
        phoneNumber: _phoneController.text,
        pin: _pinController.text,
      );

      if (isValid) {
        CustomToast.show(context, 'Xác thực thành công! ✓');
        await Future.delayed(const Duration(milliseconds: 300));
        await _moveToStep2();
        return true;
      } else {
        CustomToast.show(context, 'Số điện thoại hoặc mã PIN không chính xác', isError: true);
        return false;
      }
    } catch (e) {
      CustomToast.show(context, 'Lỗi xác thực: $e', isError: true);
      return false;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Validate Step 2: Password
  bool _validateStep2() {
    if (_passwordController.text.isEmpty) {
      CustomToast.show(context, 'Mật khẩu không được để trống', isError: true);
      return false;
    }

    if (_passwordController.text.length < 6) {
      CustomToast.show(context, 'Mật khẩu tối thiểu 6 ký tự', isError: true);
      return false;
    }

    if (_confirmPasswordController.text.isEmpty) {
      CustomToast.show(context, 'Xác nhận mật khẩu không được để trống', isError: true);
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      CustomToast.show(context, 'Mật khẩu không khớp', isError: true);
      return false;
    }

    return true;
  }

  /// Update Password
  Future<void> _handleUpdatePassword() async {
    if (!_validateStep2()) return;

    setState(() => _isLoading = true);

    try {
      final firebaseService = getIt<FirebaseService>();
      final success = await firebaseService.updatePassword(
        phoneNumber: _phoneController.text,
        newPassword: _passwordController.text,
      );

      if (success) {
        if (mounted) {
          CustomToast.show(context, 'Đặt lại mật khẩu thành công! 🎉');
          await Future.delayed(const Duration(milliseconds: 800));
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          CustomToast.show(context, 'Lỗi khi cập nhật mật khẩu', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, 'Lỗi: $e', isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _moveToStep2() async {
    _animationController.reset();
    setState(() => _currentStep = 1);
    _animationController.forward();
  }

  void _backToStep1() {
    _animationController.reset();
    setState(() => _currentStep = 0);
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quên mật khẩu'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.04),

            // Header
            _buildHeader(),
            const SizedBox(height: 32),

            // Progress Indicator
            _buildProgressIndicator(),
            const SizedBox(height: 40),

            // Step Content with Animation
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _currentStep == 0 ? _buildStep1() : _buildStep2(),
              ),
            ),

            const SizedBox(height: 40),

            // Buttons
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.warningColor.withOpacity(0.1),
                AppTheme.errorColor.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.lock_open_rounded,
            size: 40,
            color: AppTheme.warningColor,
          ),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          _currentStep == 0 ? 'Xác thực tài khoản' : 'Đặt lại mật khẩu',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          _currentStep == 0
              ? 'Nhập số điện thoại và mã PIN để xác thực tài khoản của bạn'
              : 'Tạo mật khẩu mới cho tài khoản của bạn',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightHintColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          child: _buildStepIndicator(0, 'Xác thực', _currentStep >= 0),
        ),
        Container(
          width: 30,
          height: 2,
          color: _currentStep >= 1 ? AppTheme.primaryColor : AppTheme.lightBorderColor,
        ),
        Expanded(
          child: _buildStepIndicator(1, 'Mật khẩu mới', _currentStep >= 1),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int stepNumber, String label, bool isActive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppTheme.primaryColor : AppTheme.lightBorderColor,
          ),
          child: Center(
            child: Text(
              '${stepNumber + 1}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppTheme.lightHintColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isActive ? AppTheme.primaryColor : AppTheme.lightHintColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phone Input
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(
            labelText: 'Số điện thoại',
            hintText: '(0xx) xxxx xxxx',
            prefixIcon: const Icon(Icons.phone),
            prefixIconColor: AppTheme.primaryColor,
          ),
          keyboardType: TextInputType.phone,
          inputFormatters: [_phoneMaskFormatter],
          enabled: !_isLoading,
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),

        // Formatted display
        if (_phoneController.text.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(AppPadding.md),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.infoColor, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Số chuẩn hóa: ${PhoneNormalizer.normalize(_phoneController.text)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.infoColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),

        // PIN Input
        TextFormField(
          controller: _pinController,
          decoration: InputDecoration(
            labelText: 'Mã PIN',
            hintText: 'Nhập 4-6 chữ số',
            prefixIcon: const Icon(Icons.security),
            prefixIconColor: AppTheme.primaryColor,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePin ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                setState(() => _obscurePin = !_obscurePin);
              },
            ),
          ),
          obscureText: _obscurePin,
          keyboardType: TextInputType.number,
          maxLength: 6,
          enabled: !_isLoading,
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),

        // PIN Valid Indicator
        if (_pinController.text.isNotEmpty)
          _buildValidationIndicator(
            RegExp(r'^\d{4,6}$').hasMatch(_pinController.text),
            'Mã PIN hợp lệ (4-6 chữ số)',
            'Mã PIN phải là 4-6 chữ số',
          ),

        const SizedBox(height: 24),

        // Info Box
        Container(
          padding: const EdgeInsets.all(AppPadding.md),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppTheme.warningColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nhập số điện thoại đã đăng ký và mã PIN để xác thực tài khoản của bạn.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.warningColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Password Input
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới',
            hintText: 'Nhập mật khẩu mới',
            prefixIcon: const Icon(Icons.lock),
            prefixIconColor: AppTheme.primaryColor,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          obscureText: _obscurePassword,
          enabled: !_isLoading,
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),

        // Password Strength Indicator
        if (_passwordController.text.isNotEmpty) _buildPasswordStrengthIndicator(),
        const SizedBox(height: 16),

        // Confirm Password Input
        TextFormField(
          controller: _confirmPasswordController,
          decoration: InputDecoration(
            labelText: 'Xác nhận mật khẩu',
            hintText: 'Nhập lại mật khẩu',
            prefixIcon: const Icon(Icons.lock),
            prefixIconColor: AppTheme.primaryColor,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
              },
            ),
          ),
          obscureText: _obscureConfirmPassword,
          enabled: !_isLoading,
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),

        // Match Indicator
        if (_confirmPasswordController.text.isNotEmpty)
          _buildValidationIndicator(
            _passwordController.text == _confirmPasswordController.text,
            'Mật khẩu khớp',
            'Mật khẩu không khớp',
          ),

        const SizedBox(height: 24),

        // Summary Info
        Container(
          padding: const EdgeInsets.all(AppPadding.md),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tài khoản',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightHintColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                PhoneNormalizer.formatForDisplay(_phoneController.text),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTextColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    int strength = 0;

    if (password.length >= 6) strength++;
    if (password.length >= 10) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    final strengthText = ['Yếu', 'Trung bình', 'Tốt', 'Mạnh', 'Rất mạnh'];
    final strengthColor = [
      AppTheme.errorColor,
      AppTheme.warningColor,
      AppTheme.infoColor,
      AppTheme.successColor,
      AppTheme.successColor,
    ];

    return Container(
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        color: strengthColor[strength].withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: strengthColor[strength].withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: (strength + 1) / 5,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(strengthColor[strength]),
              minHeight: 6,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            strengthText[strength],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: strengthColor[strength],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationIndicator(bool isValid, String successText, String errorText) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        color: (isValid ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: (isValid ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            color: isValid ? AppTheme.successColor : AppTheme.errorColor,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            isValid ? successText : errorText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isValid ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    final isStep1Valid = _phoneController.text.isNotEmpty &&
        PhoneNormalizer.isValid(_phoneController.text) &&
        _pinController.text.isNotEmpty &&
        RegExp(r'^\d{4,6}$').hasMatch(_pinController.text);

    final isStep2Valid = _passwordController.text.isNotEmpty &&
        _passwordController.text.length >= 6 &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text == _confirmPasswordController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Button
        ElevatedButton(
          onPressed: (_isLoading
              ? null
              : (_currentStep == 0
                  ? (isStep1Valid ? _validateStep1 : null)
                  : (isStep2Valid ? _handleUpdatePassword : null))),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_currentStep == 0 ? 'Xác thực' : 'Đặt lại mật khẩu'),
        ),
        const SizedBox(height: 12),

        // Back Button (Step 2 only)
        if (_currentStep == 1)
          OutlinedButton(
            onPressed: _isLoading ? null : _backToStep1,
            child: const Text('Quay lại'),
          ),

        const SizedBox(height: 24),

        // Link to Login
        Center(
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Quay lại đăng nhập',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _obscurePin = true;
}
