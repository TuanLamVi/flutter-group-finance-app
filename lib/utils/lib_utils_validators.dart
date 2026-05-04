class Validators {
  // Validate PIN (4-6 digits)
  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mã PIN không được để trống';
    }
    if (!RegExp(r'^\d{4,6}$').hasMatch(value)) {
      return 'Mã PIN phải từ 4-6 chữ số';
    }
    return null;
  }

  // Validate Password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    if (value.length < 6) {
      return 'Mật khẩu tối thiểu 6 ký tự';
    }
    if (value.length > 20) {
      return 'Mật khẩu tối đa 20 ký tự';
    }
    return null;
  }

  // Validate Full Name
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Họ tên không được để trống';
    }
    if (value.length < 3) {
      return 'Họ tên tối thiểu 3 ký tự';
    }
    if (value.length > 50) {
      return 'Họ tên tối đa 50 ký tự';
    }
    return null;
  }

  // Validate Address
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Địa chỉ không được để trống';
    }
    if (value.length < 5) {
      return 'Địa chỉ tối thiểu 5 ký tự';
    }
    return null;
  }

  // Validate Group Name
  static String? validateGroupName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tên nhóm không được để trống';
    }
    if (value.length < 2) {
      return 'Tên nhóm tối thiểu 2 ký tự';
    }
    if (value.length > 50) {
      return 'Tên nhóm tối đa 50 ký tự';
    }
    return null;
  }

  // Validate Amount
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số tiền không được để trống';
    }
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Số tiền phải lớn hơn 0';
    }
    if (amount > 1000000000) {
      return 'Số tiền không hợp lệ';
    }
    return null;
  }

  // Validate Comment
  static String? validateComment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bình luận không được để trống';
    }
    if (value.length > 500) {
      return 'Bình luận tối đa 500 ký tự';
    }
    return null;
  }

  // Validate Rejection Reason
  static String? validateRejectionReason(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lý do từ chối không được để trống';
    }
    if (value.length < 5) {
      return 'Lý do từ chối tối thiểu 5 ký tự';
    }
    if (value.length > 200) {
      return 'Lý do từ chối tối đa 200 ký tự';
    }
    return null;
  }
}