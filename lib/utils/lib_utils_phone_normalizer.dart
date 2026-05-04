class PhoneNormalizer {
  /// Chuẩn hóa số điện thoại
  /// Input: "+84 987 654 321" hoặc "84987654321" hoặc "0987654321"
  /// Output: "0987654321"
  static String normalize(String phoneNumber) {
    if (phoneNumber.isEmpty) return '';

    // Xóa tất cả ký tự không phải số
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Xóa dấu +
    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // Thay +84 hoặc 84 ở đầu thành 0
    if (cleaned.startsWith('84')) {
      cleaned = '0' + cleaned.substring(2);
    }

    // Validate chiều dài (VN phone: 10 chữ số)
    if (cleaned.length != 10 || !cleaned.startsWith('0')) {
      return '';
    }

    return cleaned;
  }

  /// Validate số điện thoại sau khi chuẩn hóa
  static bool isValid(String phoneNumber) {
    String normalized = normalize(phoneNumber);
    return normalized.isNotEmpty && normalized.length == 10 && normalized.startsWith('0');
  }

  /// Format hiển thị: "098 765 4321"
  static String formatForDisplay(String phoneNumber) {
    String normalized = normalize(phoneNumber);
    if (normalized.isEmpty) return phoneNumber;
    return '${normalized.substring(0, 3)} ${normalized.substring(3, 6)} ${normalized.substring(6)}';
  }
}