import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/phone_normalizer.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_toast.dart';
import '../dashboard/dashboard_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _phoneController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  int _currentStep = 0;

  // Mask formatter for phone number
  late MaskTextInputFormatter _phoneMaskFormatter;

  @override
  void initState() {
    super.initState();
    _phoneMaskFormatter = MaskTextInputFormatter(
      mask: '(###) #### ####',
      filter: {"#": RegExp(r'[0-9]')},
      type: MaskAutoCompletionType.lazy,
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  /// Validate Step 1: Phone & Full Name
  bool _validateStep1() {
    if (_phoneController.text.isEmpty) {
      CustomToast.show(context, 'Số điện thoại không được để trống', isError: true);
      return false;
    }

    if (!PhoneNormalizer.isValid(_phoneController.text)) {
      CustomToast.show(context, 'Số điện thoại không hợp lệ', isError: true);
      return false;
    }

    if (_fullNameController.text.isEmpty) {
      CustomToast.show(context, 'Họ tên không được để trống', isError: true);
      return false;
    }

    if (_fullNameController.text.length < 3) {
      CustomToast.show(context, 'Họ tên tối thiểu 3 ký tự', isError: true);
      return false;
    }

    return true;
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

  /// Validate Step 3: PIN
  bool _validateStep3() {
    if (_pinController.text.isEmpty) {
      CustomToast.show(context, 'Mã PIN không được để trống', isError: true);
      return false;
    }

    if (!RegExp(r'^\d{4,6}$').hasMatch(_pinController.text)) {
      CustomToast.show(context, 'Mã PIN phải từ 4-6 chữ số', isError: true);
      return false;
    }

    if (_confirmPinController.text.isEmpty) {
      CustomToast.show(context, 'Xác nhận mã PIN không được để trống', isError: true);
      return false;
    }

    if (_pinController.text != _confirmPinController.text) {
      CustomToast.show(context, 'Mã PIN không khớp', isError: true);
      return false;
    }

    return true;
  }

  /// Validate Step 4: Address
  bool _validateStep4() {
    if (_addressController.text.isEmpty) {
      CustomToast.show(context, 'Địa chỉ không được để trống', isError: true);
      return false;
    }

    if (_addressController.text.length < 5) {
      CustomToast.show(context, 'Địa chỉ tối thiểu 5 ký tự', isError: true);
      return false;
    }

    return true;
  }

  /// Handle Register
  Future<void> _handleRegister() async {
    if (!_validateStep4()) return;

    setState(() => _isLoading = true);

    try {
      final firebaseService = getIt<FirebaseService>();

      // Get device token
      final deviceToken = await NotificationService.instance.getDeviceToken();

      // Register user
      final user = await firebaseService.registerUser(
        phoneNumber: _phoneController.text,
        fullName: _fullNameController.text,
        password: _passwordController.text,
        pin: _pinController.text,
        address: _addressController.text,
        deviceToken: deviceToken,
      );

      if (user != null) {
        // Save to shared preferences
        final prefs = getIt<SharedPreferences>();
        await prefs.setString('user_id', user.id);
        await prefs.setString('user_phone', user.phoneNumber);
        await prefs.setString('user_name', user.fullName);

        if (mounted) {
          CustomToast.show(context, 'Đăng ký thành công! 🎉');
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          CustomToast.show(context, 'Số điện thoại đã được đăng ký', isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, 'Lỗi đăng ký: $e', isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    bool isValid = false;

    switch (_currentStep) {
      case 0:
        isValid = _validateStep1();
        break;
      case 1:
        isValid = _validateStep2();
        break;
      case 2:
        isValid = _validateStep3();
        break;
      case 3:
        isValid = _validateStep4();
        break;
    }

    if (isValid) {
      if (_currentStep < 3) {
        setState(() => _currentStep++);
      } else {
        _handleRegister();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
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
            // Progress Indicator
            _buildProgressIndicator(),
            const SizedBox(height: 32),

            // Step Content
            _buildStepContent(),
            const SizedBox(height: 32),

            // Buttons
            _buildButtons(),
            const SizedBox(height: 24),

            // Login Link
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Đã có tài khoản? ',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.lightHintColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Đăng nhập',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        // Step circles
        Row(
          children: [
            _buildStepCircle(0, 'SĐT & Tên'),
            _buildStepLine(),
            _buildStepCircle(1, 'Mật khẩu'),
            _buildStepLine(),
            _buildStepCircle(2, 'Mã PIN'),
            _buildStepLine(),
            _buildStepCircle(3, 'Địa chỉ'),
          ],
        ),
        const SizedBox(height: 16),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            minHeight: 4,
            backgroundColor: AppTheme.lightBorderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCircle(int stepNumber, String label) {
    final isActive = _currentStep == stepNumber;
    final isCompleted = _currentStep > stepNumber;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive || isCompleted ? AppTheme.primaryColor : AppTheme.lightBorderColor,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : Text(
                      '${stepNumber + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive || isCompleted ? Colors.white : AppTheme.lightHintColor,
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
              color: isActive || isCompleted ? AppTheme.primaryColor : AppTheme.lightHintColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Container(
        height: 2,
        color: _currentStep > 0 ? AppTheme.primaryColor : AppTheme.lightBorderColor,
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thông tin cơ bản',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Nhập số điện thoại và họ tên của bạn',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightHintColor,
          ),
        ),
        const SizedBox(height: 32),

        // Phone Number Input
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
        const SizedBox(height: 16),

        // Full Name Input
        TextFormField(
          controller: _fullNameController,
          decoration: InputDecoration(
            labelText: 'Họ và tên',
            hintText: 'Nhập họ tên đầy đủ',
            prefixIcon: const Icon(Icons.person),
            prefixIconColor: AppTheme.primaryColor,
          ),
          keyboardType: TextInputType.name,
          onChanged: (value) {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mật khẩu',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Tạo mật khẩu mạnh (tối thiểu 6 ký tự)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightHintColor,
          ),
        ),
        const SizedBox(height: 32),

        // Password Input
        TextFormField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            hintText: 'Nhập mật khẩu',
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
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),

        // Match Indicator
        if (_confirmPasswordController.text.isNotEmpty)
          _buildMatchIndicator(
            _passwordController.text == _confirmPasswordController.text,
            'Mật khẩu khớp',
            'Mật khẩu không khớp',
          ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mã PIN bảo mật',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Mã PIN 4-6 chữ số dùng để xác thực và khôi phục mật khẩu',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightHintColor,
          ),
        ),
        const SizedBox(height: 32),

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
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),

        // PIN Valid Indicator
        if (_pinController.text.isNotEmpty)
          _buildMatchIndicator(
            RegExp(r'^\d{4,6}$').hasMatch(_pinController.text),
            'Mã PIN hợp lệ (4-6 chữ số)',
            'Mã PIN phải là 4-6 chữ số',
          ),
        const SizedBox(height: 16),

        // Confirm PIN Input
        TextFormField(
          controller: _confirmPinController,
          decoration: InputDecoration(
            labelText: 'Xác nhận mã PIN',
            hintText: 'Nhập lại mã PIN',
            prefixIcon: const Icon(Icons.security),
            prefixIconColor: AppTheme.primaryColor,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPin ? Icons.visibility_off : Icons.visibility,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                setState(() => _obscureConfirmPin = !_obscureConfirmPin);
              },
            ),
          ),
          obscureText: _obscureConfirmPin,
          keyboardType: TextInputType.number,
          maxLength: 6,
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 16),

        // Match Indicator
        if (_confirmPinController.text.isNotEmpty)
          _buildMatchIndicator(
            _pinController.text == _confirmPinController.text,
            'Mã PIN khớp',
            'Mã PIN không khớp',
          ),

        // Security Note
        const SizedBox(height: 24),
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
              const Icon(Icons.warning_amber_rounded, color: AppTheme.warningColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nhớ lại mã PIN của bạn. Nó được dùng để khôi phục mật khẩu nếu bạn quên.',
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

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Địa chỉ',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Nhập địa chỉ liên hệ của bạn',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightHintColor,
          ),
        ),
        const SizedBox(height: 32),

        // Address Input
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Địa chỉ',
            hintText: 'Nhập địa chỉ đầy đủ',
            prefixIcon: const Icon(Icons.location_on),
            prefixIconColor: AppTheme.primaryColor,
          ),
          maxLines: 3,
          minLines: 2,
          keyboardType: TextInputType.multiline,
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: 32),

        // Summary Card
        _buildSummaryCard(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(AppPadding.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.secondaryColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tóm tắt thông tin',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTextColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryItem('📱 Số điện thoại', PhoneNormalizer.formatForDisplay(_phoneController.text)),
          const SizedBox(height: 12),
          _buildSummaryItem('👤 Họ và tên', _fullNameController.text),
          const SizedBox(height: 12),
          _buildSummaryItem('🔒 Mật khẩu', '*' * _passwordController.text.length),
          const SizedBox(height: 12),
          _buildSummaryItem('🔐 Mã PIN', '*' * _pinController.text.length),
          const SizedBox(height: 12),
          _buildSummaryItem('📍 Địa chỉ', _addressController.text),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.lightHintColor,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTextColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
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

  Widget _buildMatchIndicator(bool isMatch, String successText, String errorText) {
    return Container(
      padding: const EdgeInsets.all(AppPadding.md),
      decoration: BoxDecoration(
        color: (isMatch ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: (isMatch ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isMatch ? Icons.check_circle : Icons.cancel,
            color: isMatch ? AppTheme.successColor : AppTheme.errorColor,
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(
            isMatch ? successText : errorText,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isMatch ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      children: [
        // Back Button
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              child: const Text('Quay lại'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),

        // Next/Register Button
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _nextStep,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(_currentStep == 3 ? 'Đăng ký' : 'Tiếp tục'),
          ),
        ),
      ],
    );
  }
}
