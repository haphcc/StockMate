import 'package:flutter/material.dart';

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
      isVietnamese ? 'Tài khoản / SĐT / CCCD' : 'Account / Phone / ID';
  String get accountHint =>
      isVietnamese ? 'Nhập 09xx, CCCD hoặc mã 086C...' : 'Enter 09xx, ID or 086C...';
  String get passwordLabel =>
      isVietnamese ? 'Mật khẩu PIN / Đăng nhập' : 'PIN / Password';
  String get passwordHint => '••••••••••••';
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
  String get contactLabel =>
      isVietnamese ? 'Số điện thoại hoặc Email nhận mã OTP' : 'Phone number or Email for OTP';
  String get contactHint =>
      isVietnamese ? '0912 345 678 hoặc investor@stockmate.vn' : '0912 345 678 or investor@stockmate.vn';
  String get passwordRegisterLabel =>
      isVietnamese ? 'Mật khẩu tài khoản' : 'Account password';
  String get passwordRegisterHint =>
      isVietnamese ? 'Tối thiểu 8 ký tự, 1 số, 1 chữ hoa' : 'Min 8 chars, 1 number, 1 uppercase';
  String get confirmPasswordLabel =>
      isVietnamese ? 'Xác nhận mật khẩu' : 'Confirm password';
  String get confirmPasswordHint =>
      isVietnamese ? 'Nhập lại mật khẩu' : 'Re-enter password';
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
      isVietnamese ? 'Tạo Tài Khoản & Nhận 1 Tỷ Đ' : 'Create Account & Get 1B VND';
  String get orRegisterWith =>
      isVietnamese ? 'HOẶC ĐĂNG KÝ NHANH' : 'OR QUICK REGISTER';
  String get alreadyHaveAccount =>
      isVietnamese ? 'Đã có tài khoản? ' : 'Already have an account? ';
  String get loginLink =>
      isVietnamese ? 'Đăng nhập' : 'Sign in';
  String get termsAgreeError =>
      isVietnamese ? 'Vui lòng đồng ý với Điều khoản dịch vụ' : 'Please agree to the Terms of Service';

  // Password rules & strength
  String get strengthNotEntered =>
      isVietnamese ? 'Chưa nhập' : 'Not entered';
  String get strengthWeak =>
      isVietnamese ? 'Yếu' : 'Weak';
  String get strengthFair =>
      isVietnamese ? 'Trung bình' : 'Fair';
  String get strengthGood =>
      isVietnamese ? 'Khá' : 'Good';
  String get strengthStrong =>
      isVietnamese ? 'Mạnh' : 'Strong';

  String get ruleMinChars =>
      isVietnamese ? '8+ ký tự' : '8+ chars';
  String get ruleUppercase =>
      isVietnamese ? 'Chữ hoa' : 'Uppercase';
  String get ruleNumber =>
      isVietnamese ? 'Chữ số' : 'Number';
  String get ruleSpecial =>
      isVietnamese ? 'Ký tự đặc biệt (!@#...)' : 'Special char (!@#...)';

  // --- Profile Screen ---
  String get profileTitle =>
      isVietnamese ? 'Hồ sơ cá nhân' : 'Personal Profile';
  String get profileSubtitle =>
      isVietnamese ? 'Quản lý tài khoản & cài đặt hệ thống' : 'Manage account & system settings';
  String get accountVerifiedBadge =>
      isVietnamese ? 'Đã xác thực eKYC' : 'eKYC Verified';
  String get accountStandardBadge =>
      isVietnamese ? 'Tài khoản tiêu chuẩn' : 'Standard Account';

  String get sectionGeneral =>
      isVietnamese ? 'Thông tin cá nhân' : 'Personal Information';
  String get labelFullName =>
      isVietnamese ? 'Họ và tên' : 'Full name';
  String get labelAccountNumber =>
      isVietnamese ? 'Số tài khoản' : 'Account number';
  String get labelPhone =>
      isVietnamese ? 'Số điện thoại' : 'Phone number';
  String get labelEmail =>
      isVietnamese ? 'Email' : 'Email';
  String get labelStatus =>
      isVietnamese ? 'Trạng thái' : 'Status';
  String get statusActive =>
      isVietnamese ? 'Hoạt động' : 'Active';

  String get sectionPreferences =>
      isVietnamese ? 'Cài đặt ứng dụng' : 'App Preferences';
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
      isVietnamese ? 'Bảo mật & Tài khoản' : 'Security & Account';
  String get changePassword =>
      isVietnamese ? 'Đổi mật khẩu' : 'Change Password';
  String get changePin =>
      isVietnamese ? 'Đổi mã PIN giao dịch' : 'Change Trading PIN';
  String get twoFactorAuth =>
      isVietnamese ? 'Xác thực 2 yếu tố (2FA)' : 'Two-Factor Authentication (2FA)';

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
  String get tabOrders =>
      isVietnamese ? 'Sổ lệnh' : 'Orders';
  String get tabTrade =>
      isVietnamese ? 'Đặt lệnh' : 'Trade';
  String get tabPortfolio =>
      isVietnamese ? 'Danh mục' : 'Portfolio';
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
