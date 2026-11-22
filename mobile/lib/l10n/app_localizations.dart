import 'package:flutter/material.dart';

/// Lớp quản lý đa ngôn ngữ (Tiếng Việt & Tiếng Anh) cho StockMate.
/// Hỗ trợ chuyển đổi ngôn ngữ tức thì trong toàn bộ ứng dụng.
class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = [
    Locale('vi'),
    Locale('en'),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        const AppLocalizations(Locale('vi'));
  }

  bool get isVietnamese => locale.languageCode == 'vi';

  // --- Common ---
  String get appName => 'StockMate';
  String get vietnamese => isVietnamese ? 'Tiếng Việt' : 'Vietnamese';
  String get english => isVietnamese ? 'Tiếng Anh' : 'English';
  String get language => isVietnamese ? 'Ngôn ngữ' : 'Language';
  String get cancel => isVietnamese ? 'Hủy' : 'Cancel';
  String get confirm => isVietnamese ? 'Xác nhận' : 'Confirm';
  String get save => isVietnamese ? 'Lưu' : 'Save';
  String get close => isVietnamese ? 'Đóng' : 'Close';
  String get loading => isVietnamese ? 'Đang tải...' : 'Loading...';
  String get back => isVietnamese ? 'Quay lại' : 'Back';
  String get or => isVietnamese ? 'Hoặc' : 'Or';

  // --- Login Screen ---
  String get loginTitle =>
      isVietnamese ? 'Đăng nhập tài khoản' : 'Sign In to Account';
  String get accountLabel =>
      isVietnamese ? 'Tài khoản / Email' : 'Email / Account';
  String get accountHint => 'investor@stockmate.vn';
  String get emailInvalid =>
      isVietnamese ? 'Email không hợp lệ' : 'Invalid email format';
  String get passwordLabel =>
      isVietnamese ? 'Mật khẩu PIN / Đăng nhập' : 'Password / PIN';
  String get passwordHint => '••••••••••••';
  String get passwordMinLength =>
      isVietnamese ? 'Mật khẩu tối thiểu 8 ký tự' : 'Password must be at least 8 characters';
  String get rememberMe => isVietnamese ? 'Ghi nhớ' : 'Remember me';
  String get forgotPassword =>
      isVietnamese ? 'Quên mật khẩu?' : 'Forgot password?';
  String get loginButton =>
      isVietnamese ? 'Đăng Nhập Ngay' : 'Sign In Now';
  String get orLoginWith =>
      isVietnamese ? 'HOẶC ĐĂNG NHẬP QUA' : 'OR SIGN IN WITH';
  String get noAccount =>
      isVietnamese ? 'Chưa có tài khoản? ' : "Don't have an account? ";
  String get registerNow =>
      isVietnamese ? 'Đăng ký ngay' : 'Register now';
  String get loginSuccess =>
      isVietnamese ? 'Đăng nhập thành công' : 'Login successful';
  String get loginFailed =>
      isVietnamese ? 'Đăng nhập không thành công' : 'Login failed';

  // --- Register Screen ---
  String get registerTitle =>
      isVietnamese ? 'Tạo tài khoản StockMate' : 'Create StockMate Account';
  String get fullNameLabel =>
      isVietnamese ? 'Họ và tên (như trên CCCD)' : 'Full name (as on ID card)';
  String get fullNameHint =>
      isVietnamese ? 'VD: NGUYEN VAN A' : 'e.g. NGUYEN VAN A';
  String get emailLabel =>
      isVietnamese ? 'Email nhận mã OTP & thông báo' : 'Email for OTP & notices';
  String get emailHint => 'investor@stockmate.vn';
  String get phoneLabel =>
      isVietnamese ? 'Số điện thoại' : 'Phone number';
  String get phoneHint => '0912 345 678';
  String get phoneInvalid =>
      isVietnamese ? 'Số điện thoại không hợp lệ' : 'Invalid phone number';
  String get passwordRegisterLabel =>
      isVietnamese ? 'Mật khẩu tài khoản' : 'Account password';
  String get passwordRegisterHint =>
      isVietnamese ? 'Tối thiểu 8 ký tự, 1 số, 1 chữ hoa' : 'Min 8 chars, 1 number, 1 uppercase';
  String get confirmPasswordLabel =>
      isVietnamese ? 'Xác nhận mật khẩu' : 'Confirm password';
  String get confirmPasswordHint =>
      isVietnamese ? 'Nhập lại mật khẩu' : 'Re-enter password';
  String get passwordMismatch =>
      isVietnamese ? 'Mật khẩu xác nhận không khớp' : 'Passwords do not match';
  String get termsRequired =>
      isVietnamese ? 'Vui lòng đồng ý với Điều khoản dịch vụ' : 'Please agree to the Terms of Service';
  String get referralOptional =>
      isVietnamese ? 'Mã giới thiệu (tùy chọn)' : 'Referral code (optional)';
  String get referralHint =>
      isVietnamese ? 'Nhập mã giới thiệu người thân/bạn bè' : 'Enter referral code from friends/family';
  String get agreeTermsPrefix =>
      isVietnamese ? 'Tôi đồng ý với ' : 'I agree with the ';
  String get termsOfService =>
      isVietnamese ? 'Điều khoản dịch vụ' : 'Terms of Service';
  String get termsAndUnderstand =>
      isVietnamese ? ' và hiểu rõ đây là ' : ' and understand this is a ';
  String get termsRiskFree =>
      isVietnamese ? 'môi trường giao dịch chứng khoán giả lập rủi ro 0 đồng' : 'zero-risk simulated stock trading environment';
  String get termsPurpose =>
      isVietnamese ? ' phục vụ học tập, rèn luyện kỹ năng.' : ' for learning and skill development.';
  String get registerButton =>
      isVietnamese ? 'Tạo Tài Khoản & Nhận 100.000đ' : 'Create Account & Get 100,000 VND';
  String get orRegisterWith =>
      isVietnamese ? 'HOẶC ĐĂNG KÝ NHANH' : 'OR QUICK REGISTER';
  String get alreadyHaveAccount =>
      isVietnamese ? 'Đã có tài khoản? ' : 'Already have an account? ';
  String get loginNow =>
      isVietnamese ? 'Đăng nhập' : 'Sign in';

  // Password Strength
  String get strengthEmpty =>
      isVietnamese ? 'Chưa nhập' : 'Empty';
  String get strengthWeak =>
      isVietnamese ? 'Yếu' : 'Weak';
  String get strengthMedium =>
      isVietnamese ? 'Trung bình' : 'Medium';
  String get strengthGood =>
      isVietnamese ? 'Khá' : 'Good';
  String get strengthStrong =>
      isVietnamese ? 'Mạnh' : 'Strong';

  String get ruleMinLength =>
      isVietnamese ? '8+ ký tự' : '8+ chars';
  String get ruleUppercase =>
      isVietnamese ? 'Chữ hoa' : 'Uppercase';
  String get ruleNumber =>
      isVietnamese ? 'Chữ số' : 'Number';
  String get ruleSpecial =>
      isVietnamese ? 'Ký tự đặc biệt (!@#...)' : 'Special char (!@#...)';

  // --- Profile / Settings Screen ---
  String get profileTitle =>
      isVietnamese ? 'Hồ sơ cá nhân' : 'Personal Profile';
  String get profileSubtitle =>
      isVietnamese ? 'Quản lý tài khoản & cài đặt hệ thống' : 'Manage account & system settings';
  String get settingsAndAccount =>
      isVietnamese ? 'Cài đặt & Tài khoản' : 'Settings & Account';
  String get accountVerifiedBadge =>
      isVietnamese ? 'Đã xác thực eKYC' : 'eKYC Verified';
  String get accountStandardBadge =>
      isVietnamese ? 'Tài khoản tiêu chuẩn' : 'Standard Account';

  String get sectionGeneral =>
      isVietnamese ? 'TÀI KHOẢN' : 'ACCOUNT';
  String get editProfile =>
      isVietnamese ? 'Sửa thông tin' : 'Edit profile';
  String get labelFullName =>
      isVietnamese ? 'Họ và tên' : 'Full name';
  String get labelAccountNumber =>
      isVietnamese ? 'Số tài khoản' : 'Account number';
  String get labelPhone =>
      isVietnamese ? 'Số điện thoại' : 'Phone number';
  String get labelEmail =>
      isVietnamese ? 'Email' : 'Email';
  String get labelLoginMethod =>
      isVietnamese ? 'Đăng nhập' : 'Sign in method';
  String get googleAccount =>
      isVietnamese ? 'Tài khoản Google' : 'Google Account';
  String get emailPasswordAccount =>
      isVietnamese ? 'Email & Mật khẩu' : 'Email & Password';
  String get labelRole =>
      isVietnamese ? 'Vai trò' : 'Role';
  String get labelStatus =>
      isVietnamese ? 'Trạng thái' : 'Status';
  String get statusActive =>
      isVietnamese ? 'Hoạt động' : 'Active';

  String get sectionPreferences =>
      isVietnamese ? 'CÀI ĐẶT & NGÔN NGỮ' : 'PREFERENCES & LANGUAGE';
  String get labelLanguage =>
      isVietnamese ? 'Ngôn ngữ hiển thị' : 'Display Language';
  String get selectLanguage =>
      isVietnamese ? 'Chọn ngôn ngữ' : 'Select Language';
  String get labelTheme =>
      isVietnamese ? 'Giao diện' : 'Theme Mode';
  String get darkMode =>
      isVietnamese ? 'Chế độ tối' : 'Dark Mode';
  String get lightMode =>
      isVietnamese ? 'Chế độ sáng' : 'Light Mode';
  String get labelBiometrics =>
      isVietnamese ? 'Xác thực sinh trắc học' : 'Biometric Authentication';
  String get biometricsDesc =>
      isVietnamese ? 'Đăng nhập nhanh bằng Face ID / Vân tay' : 'Quick sign in with Face ID / Fingerprint';

  String get sectionSecurity =>
      isVietnamese ? 'BẢO MẬT' : 'SECURITY';
  String get changePassword =>
      isVietnamese ? 'Đổi mật khẩu' : 'Change Password';
  String get setPassword =>
      isVietnamese ? 'Đặt mật khẩu' : 'Set Password';
  String get updatePasswordDesc =>
      isVietnamese ? 'Cập nhật mật khẩu tài khoản' : 'Update account password';
  String get setPasswordDesc =>
      isVietnamese ? 'Đặt mật khẩu để có thể đăng nhập bằng email' : 'Set password to enable email sign in';
  String get changePin =>
      isVietnamese ? 'Đổi mã PIN giao dịch' : 'Change Trading PIN';
  String get twoFactorAuth =>
      isVietnamese ? 'Xác thực 2 yếu tố (2FA)' : 'Two-Factor Authentication (2FA)';

  String get sectionApplication =>
      isVietnamese ? 'ỨNG DỤNG' : 'APPLICATION';
  String get sectionSupport =>
      isVietnamese ? 'Hỗ trợ & Thông tin' : 'Support & Information';
  String get helpCenter =>
      isVietnamese ? 'Trung tâm trợ giúp' : 'Help Center';
  String get contactSupport =>
      isVietnamese ? 'Tổng đài hỗ trợ (1900 xxxx)' : 'Hotline Support (1900 xxxx)';
  String get termsAndPolicies =>
      isVietnamese ? 'Điều khoản & Chính sách' : 'Terms & Policies';
  String get appVersion =>
      isVietnamese ? 'Phiên bản ứng dụng' : 'App Version';

  String get logoutButton =>
      isVietnamese ? 'Đăng xuất tài khoản' : 'Log Out';
  String get logoutConfirmTitle =>
      isVietnamese ? 'Xác nhận đăng xuất' : 'Confirm Logout';
  String get logoutConfirmMessage =>
      isVietnamese ? 'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng StockMate?' : 'Are you sure you want to log out of StockMate?';

  // --- Bottom Navigation & Shell ---
  String get tabMarket =>
      isVietnamese ? 'Thị trường' : 'Market';
  String get tabWatchlist =>
      isVietnamese ? 'Theo dõi' : 'Watchlist';
  String get tabTrade =>
      isVietnamese ? 'Đặt lệnh' : 'Trade';
  String get tabOrders =>
      isVietnamese ? 'Sổ lệnh' : 'Orders';
  String get tabPortfolio =>
      isVietnamese ? 'Danh mục' : 'Portfolio';
  String get tabAdmin =>
      isVietnamese ? 'Quản trị' : 'Admin';
  String get tabProfile =>
      isVietnamese ? 'Hồ sơ' : 'Profile';

  // --- Dashboard & Portfolio ---
  String get totalNetAssets =>
      isVietnamese ? 'Tổng tài sản ròng' : 'Total Net Assets';
  String get buyingPower =>
      isVietnamese ? 'Sức mua' : 'Buying Power';
  String get profitLoss =>
      isVietnamese ? 'Lãi / Lỗ' : 'Profit / Loss';
  String get holdingsHeader =>
      isVietnamese ? 'DANH MỤC NẮM GIỮ' : 'HOLDINGS';
  String get noHoldings =>
      isVietnamese ? 'Chưa có cổ phiếu nào trong danh mục' : 'No holdings in portfolio';
  String holdingsCount(int count) =>
      isVietnamese ? '$count mã' : '$count stocks';
  String get deposit =>
      isVietnamese ? 'Nạp tiền' : 'Deposit';
  String get withdraw =>
      isVietnamese ? 'Rút tiền' : 'Withdraw';
  String get transfer =>
      isVietnamese ? 'Chuyển tiền' : 'Transfer';
  String get portfolioTitle =>
      isVietnamese ? 'Danh mục đầu tư' : 'Investment Portfolio';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['vi', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
