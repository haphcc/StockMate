import 'package:flutter/material.dart';

/// Lớp quản lý đa ngôn ngữ (Tiếng Việt & Tiếng Anh) cho toàn bộ ứng dụng StockMate.
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

  // ================= COMMON =================
  String get appName => 'StockMate';
  String get vietnamese => isVietnamese ? 'Tiếng Việt' : 'Vietnamese';
  String get english => isVietnamese ? 'Tiếng Anh' : 'English';
  String get language => isVietnamese ? 'Ngôn ngữ' : 'Language';
  String get cancel => isVietnamese ? 'Hủy' : 'Cancel';
  String get confirm => isVietnamese ? 'Xác nhận' : 'Confirm';
  String get save => isVietnamese ? 'Lưu' : 'Save';
  String get close => isVietnamese ? 'Đóng' : 'Close';
  String get loading => isVietnamese ? 'Đang tải...' : 'Loading...';
  String get reload => isVietnamese ? 'Tải lại' : 'Reload';
  String get retry => isVietnamese ? 'Thử lại' : 'Retry';
  String get back => isVietnamese ? 'Quay lại' : 'Back';
  String get or => isVietnamese ? 'Hoặc' : 'Or';
  String get search => isVietnamese ? 'Tìm kiếm' : 'Search';
  String get filter => isVietnamese ? 'Bộ lọc' : 'Filter';
  String get all => isVietnamese ? 'Tất cả' : 'All';
  String get today => isVietnamese ? 'Hôm nay' : 'Today';
  String get error => isVietnamese ? 'Lỗi' : 'Error';
  String get success => isVietnamese ? 'Thành công' : 'Success';
  String get copied => isVietnamese ? 'Đã sao chép vào bộ nhớ tạm' : 'Copied to clipboard';

  // ================= LOGIN SCREEN =================
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

  // ================= REGISTER SCREEN =================
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

  // ================= PROFILE / SETTINGS SCREEN =================
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

  // ================= BOTTOM NAVIGATION & SHELL =================
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

  // ================= DASHBOARD & HOME =================
  String get marketIndices =>
      isVietnamese ? 'Chỉ số thị trường' : 'Market Indices';
  String get searchStockTooltip =>
      isVietnamese ? 'Tìm kiếm cổ phiếu' : 'Search stock';
  String get notificationTooltip =>
      isVietnamese ? 'Thông báo' : 'Notifications';
  String get accountTooltip =>
      isVietnamese ? 'Tài khoản' : 'Account';
  String get selectAccount =>
      isVietnamese ? 'Chọn tài khoản' : 'Select Account';
  String get accountPrefix =>
      isVietnamese ? 'Tài khoản' : 'Account';
  String get cashBalance =>
      isVietnamese ? 'Số dư tiền mặt' : 'Cash Balance';
  String get marketLabel =>
      isVietnamese ? 'Thị trường' : 'Market';
  String get marketBreadth =>
      isVietnamese ? 'Độ rộng thị trường' : 'Market Breadth';
  String get gainers =>
      isVietnamese ? 'Tăng' : 'Gain';
  String get losers =>
      isVietnamese ? 'Giảm' : 'Loss';
  String get unchanged =>
      isVietnamese ? 'Tham chiếu' : 'Ref';
  String get hotNews =>
      isVietnamese ? 'Tin tức & Tiêu điểm' : 'News & Highlights';
  String get priceBoardHeader =>
      isVietnamese ? 'Bảng giá trực tuyến' : 'Live Price Board';
  String get sortTooltip =>
      isVietnamese ? 'Tùy chọn sắp xếp' : 'Sort Options';

  // Categories
  String get catAll => isVietnamese ? 'Tất cả' : 'All';
  String get catBanking => isVietnamese ? 'Ngân hàng' : 'Banking';
  String get catRealEstate => isVietnamese ? 'Bất động sản' : 'Real Estate';
  String get catSecurities => isVietnamese ? 'Chứng khoán' : 'Securities';
  String get catSteel => isVietnamese ? 'Thép' : 'Steel';
  String get catEnergy => isVietnamese ? 'Năng lượng' : 'Energy';
  String get catRetail => isVietnamese ? 'Bán lẻ & Tiêu dùng' : 'Retail & Consumer';

  // Sort Options
  String get sortTopVolume => isVietnamese ? 'Top Khối lượng' : 'Top Volume';
  String get sortTopGain => isVietnamese ? 'Top Tăng giá' : 'Top Gainers';
  String get sortTopLoss => isVietnamese ? 'Top Giảm giá' : 'Top Losers';
  String get sortPriceHigh => isVietnamese ? 'Giá cao nhất' : 'Highest Price';
  String get sortPriceLow => isVietnamese ? 'Giá thấp nhất' : 'Lowest Price';
  String get sortAlpha => isVietnamese ? 'Mã A - Z' : 'Symbol A - Z';

  // ================= PORTFOLIO & ASSETS =================
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
  String get availableTotal =>
      isVietnamese ? 'Khả dụng / Tổng' : 'Available / Total';
  String get costCurrentPrice =>
      isVietnamese ? 'Giá vốn / Hiện tại' : 'Avg Cost / Current';
  String get marketValue =>
      isVietnamese ? 'Giá trị thị trường' : 'Market Value';
  String get buyMore =>
      isVietnamese ? 'Mua thêm' : 'Buy More';
  String get sell =>
      isVietnamese ? 'Bán' : 'Sell';
  String get waitingShares =>
      isVietnamese ? 'Chờ về' : 'Pending';
  String get viewCandleChart =>
      isVietnamese ? 'Xem biểu đồ nến' : 'Candle Chart';

  // ================= WATCHLIST SCREEN =================
  String get watchlistTitle =>
      isVietnamese ? 'Danh sách theo dõi' : 'Watchlist';
  String get watchlistSubtitle =>
      isVietnamese ? 'Các mã bạn đang quan tâm' : 'Stocks on your watchlist';
  String get emptyWatchlistGroup =>
      isVietnamese ? 'Chưa có mã nào trong nhóm này.' : 'No stocks in this group.';
  String removedFromWatchlist(String symbol) =>
      isVietnamese ? 'Đã bỏ theo dõi mã $symbol' : 'Removed $symbol from watchlist';
  String addedToWatchlist(String symbol) =>
      isVietnamese ? 'Đã thêm $symbol vào danh sách theo dõi' : 'Added $symbol to watchlist';
  String get addStockToWatchlist =>
      isVietnamese ? 'Thêm mã theo dõi' : 'Add Stock to Watchlist';
  String get selectStockToAdd =>
      isVietnamese ? 'Chọn mã cổ phiếu muốn theo dõi' : 'Select a stock to watch';
  String get alreadyInWatchlist =>
      isVietnamese ? 'Mã này đã có trong danh sách' : 'Stock is already in watchlist';

  // ================= PLACE ORDER SCREEN =================
  String get tradeTitle =>
      isVietnamese ? 'Giao dịch' : 'Trade';
  String get limitOrderType =>
      isVietnamese ? 'Đặt lệnh giới hạn (LO)' : 'Limit Order (LO)';
  String get orderBuy =>
      isVietnamese ? 'MUA' : 'BUY';
  String get orderSell =>
      isVietnamese ? 'BÁN' : 'SELL';
  String get symbolLabel =>
      isVietnamese ? 'Mã cổ phiếu' : 'Symbol';
  String get quantityLabel =>
      isVietnamese ? 'Khối lượng' : 'Quantity';
  String get priceLabel =>
      isVietnamese ? 'Giá đặt' : 'Order Price';
  String get estimatedTotal =>
      isVietnamese ? 'Giá trị ước tính' : 'Estimated Value';
  String get tradingFeeEstimate =>
      isVietnamese ? 'Phí giao dịch (0.15%)' : 'Trading Fee (0.15%)';
  String get totalPayable =>
      isVietnamese ? 'Tổng tiền thanh toán' : 'Total Amount';
  String get availableCashLabel =>
      isVietnamese ? 'Tiền mặt khả dụng' : 'Available Cash';
  String get availableSharesLabel =>
      isVietnamese ? 'CP khả dụng' : 'Available Shares';
  String get floorPriceLabel =>
      isVietnamese ? 'Sàn' : 'Floor';
  String get refPriceLabel =>
      isVietnamese ? 'TC' : 'Ref';
  String get ceilingPriceLabel =>
      isVietnamese ? 'Trần' : 'Ceil';
  String get maxQuantity =>
      isVietnamese ? 'Tối đa' : 'Max';
  String get statRef =>
      isVietnamese ? 'Tham chiếu' : 'Reference';
  String get statCeil =>
      isVietnamese ? 'Trần' : 'Ceiling';
  String get statFloor =>
      isVietnamese ? 'Sàn' : 'Floor';
  String get statVolume =>
      isVietnamese ? 'Khối lượng' : 'Volume';
  String get btnPlaceBuyOrder =>
      isVietnamese ? 'ĐẶT LỆNH MUA' : 'PLACE BUY ORDER';
  String get btnPlaceSellOrder =>
      isVietnamese ? 'ĐẶT LỆNH BÁN' : 'PLACE SELL ORDER';
  String get orderSubmittedSuccess =>
      isVietnamese ? 'Đặt lệnh thành công!' : 'Order placed successfully!';
  String get errPriceBelowFloor =>
      isVietnamese ? 'Giá thấp hơn giá sàn' : 'Price below floor price';
  String get errPriceAboveCeiling =>
      isVietnamese ? 'Giá cao hơn giá trần' : 'Price above ceiling price';
  String errTickSize(String exchange, int tick) =>
      isVietnamese ? 'Bước giá sàn $exchange là $tick đ' : 'Tick size for $exchange is $tick VND';
  String get errQuantityMultiple100 =>
      isVietnamese ? 'Khối lượng phải là bội số của 100' : 'Quantity must be a multiple of 100';
  String get errInsufficientCash =>
      isVietnamese ? 'Số dư tiền mặt không đủ để đặt lệnh' : 'Insufficient cash balance';
  String get errInsufficientShares =>
      isVietnamese ? 'Số lượng cổ phiếu khả dụng không đủ' : 'Insufficient available shares';

  // ================= ORDER BOOK SCREEN =================
  String get orderBookTitle =>
      isVietnamese ? 'Sổ lệnh' : 'Order Book';
  String get orderBookSubtitle =>
      isVietnamese ? 'Theo dõi các lệnh đã đặt' : 'Track your placed orders';
  String get filterOpenOrders =>
      isVietnamese ? 'Đang mở' : 'Open';
  String get statusPending =>
      isVietnamese ? 'Chờ khớp' : 'Pending';
  String get statusPartial =>
      isVietnamese ? 'Khớp một phần' : 'Partial';
  String get statusCompleted =>
      isVietnamese ? 'Đã khớp' : 'Filled';
  String get statusCancelled =>
      isVietnamese ? 'Đã hủy' : 'Cancelled';
  String get statusRejected =>
      isVietnamese ? 'Bị từ chối' : 'Rejected';
  String get btnCancelOrder =>
      isVietnamese ? 'Hủy lệnh' : 'Cancel Order';
  String get confirmCancelOrderTitle =>
      isVietnamese ? 'Xác nhận hủy lệnh' : 'Confirm Cancel Order';
  String confirmCancelOrderMsg(String id, String symbol) =>
      isVietnamese ? 'Bạn có chắc chắn muốn hủy lệnh $id ($symbol)?' : 'Are you sure you want to cancel order $id ($symbol)?';
  String get cancelOrderSuccess =>
      isVietnamese ? 'Đã gửi yêu cầu hủy lệnh' : 'Order cancellation submitted';
  String get noOrdersFound =>
      isVietnamese ? 'Không có lệnh nào' : 'No orders found';

  // ================= TRANSACTION HISTORY SCREEN =================
  String get transactionHistoryTitle =>
      isVietnamese ? 'Lịch sử giao dịch' : 'Transaction History';
  String get transactionHistorySubtitle =>
      isVietnamese ? 'Khớp lệnh & Phí giao dịch' : 'Executions & Trading Fees';
  String get settlementDate =>
      isVietnamese ? 'Ngày thanh toán' : 'Settlement Date';
  String get settledStatus =>
      isVietnamese ? 'Đã thanh toán' : 'Settled';
  String get pendingSettlement =>
      isVietnamese ? 'Đang chờ thanh toán' : 'Pending Settlement';
  String get noTransactionsFound =>
      isVietnamese ? 'Chưa có giao dịch nào' : 'No transactions recorded';

  // ================= DEPOSIT SCREEN =================
  String get depositTitle =>
      isVietnamese ? 'Nạp tiền vào tài khoản' : 'Deposit Funds';
  String get depositSubtitle =>
      isVietnamese ? 'Nạp tiền tự động 24/7 qua VietQR' : 'Instant 24/7 Deposit via VietQR';
  String get depositAmountLabel =>
      isVietnamese ? 'Số tiền nạp (VND)' : 'Deposit Amount (VND)';
  String get depositAmountHint => '100.000';
  String get btnGenerateQR =>
      isVietnamese ? 'Tạo mã VietQR nạp tiền' : 'Generate VietQR';
  String get btnGeneratingQR =>
      isVietnamese ? 'Đang tạo mã QR...' : 'Generating QR...';
  String get depositSuccessTitle =>
      isVietnamese ? 'Nạp tiền thành công!' : 'Deposit Successful!';
  String depositSuccessMsg(String amount) =>
      isVietnamese ? 'Tài khoản của bạn đã được cộng $amount.' : 'Your account has been credited with $amount.';
  String get scanQrInstruction =>
      isVietnamese ? 'Mở ứng dụng ngân hàng và quét mã VietQR để thanh toán' : 'Open your banking app and scan VietQR to pay';
  String get beneficiaryBank =>
      isVietnamese ? 'Ngân hàng thụ hưởng' : 'Beneficiary Bank';
  String get transferContent =>
      isVietnamese ? 'Nội dung chuyển khoản' : 'Transfer Content';
  String get importantTransferNote =>
      isVietnamese ? 'Lưu ý: Giữ nguyên nội dung chuyển khoản để tiền vào tài khoản tự động trong 30 giây.' : 'Note: Keep the transfer content exact for instant credit within 30 seconds.';

  // ================= NOTIFICATIONS SCREEN & SHEET =================
  String get notificationsTitle =>
      isVietnamese ? 'Thông báo' : 'Notifications';
  String get markAllAsRead =>
      isVietnamese ? 'Đánh dấu đã đọc tất cả' : 'Mark all as read';
  String get unreadOnly =>
      isVietnamese ? 'Chỉ chưa đọc' : 'Unread only';
  String get noNotifications =>
      isVietnamese ? 'Không có thông báo nào' : 'No notifications';
  String get notifTypeOrder =>
      isVietnamese ? 'Lệnh' : 'Order';
  String get notifTypeAccount =>
      isVietnamese ? 'Tài khoản' : 'Account';
  String get notifTypeMarket =>
      isVietnamese ? 'Thị trường' : 'Market';
  String get notifTypeSystem =>
      isVietnamese ? 'Hệ thống' : 'System';
  String get justNow =>
      isVietnamese ? 'Vừa xong' : 'Just now';
  String minutesAgo(int m) =>
      isVietnamese ? '$m phút trước' : '$m mins ago';
  String hoursAgo(int h) =>
      isVietnamese ? '$h giờ trước' : '$h hrs ago';
  String daysAgo(int d) =>
      isVietnamese ? '$d ngày trước' : '$d days ago';

  // ================= STOCK DETAIL SCREEN =================
  String get stockDetailTitle =>
      isVietnamese ? 'Chi tiết cổ phiếu' : 'Stock Detail';
  String get technicalChart =>
      isVietnamese ? 'Biểu đồ kỹ thuật' : 'Technical Chart';
  String get orderDepth =>
      isVietnamese ? 'Độ sâu khớp lệnh' : 'Order Depth';
  String get buyVolumeDepth =>
      isVietnamese ? 'Bên Mua' : 'Bid';
  String get sellVolumeDepth =>
      isVietnamese ? 'Bên Bán' : 'Ask';
  String get currentMatching =>
      isVietnamese ? 'Khớp lệnh' : 'Match';
  String get basicInfo =>
      isVietnamese ? 'Thông tin cơ bản' : 'Overview';
  String get exchangeLabel =>
      isVietnamese ? 'Sàn' : 'Exchange';
  String get industryLabel =>
      isVietnamese ? 'Ngành' : 'Industry';
  String get volumeLabel =>
      isVietnamese ? 'Tổng KL' : 'Total Vol';

  // ================= DIALOGS =================
  String get searchStockHint =>
      isVietnamese ? 'Nhập mã cổ phiếu hoặc tên công ty...' : 'Search symbol or company name...';
  String get searchResults =>
      isVietnamese ? 'Kết quả tìm kiếm' : 'Search Results';
  String get noStocksFound =>
      isVietnamese ? 'Không tìm thấy cổ phiếu phù hợp' : 'No matching stocks found';
  String get editProfileTitle =>
      isVietnamese ? 'Chỉnh sửa thông tin cá nhân' : 'Edit Personal Profile';
  String get changePasswordTitle =>
      isVietnamese ? 'Đổi mật khẩu tài khoản' : 'Change Account Password';
  String get currentPasswordLabel =>
      isVietnamese ? 'Mật khẩu hiện tại' : 'Current Password';
  String get currentPasswordHint => '••••••••••••';
  String get newPasswordLabel =>
      isVietnamese ? 'Mật khẩu mới' : 'New Password';
  String get newPasswordHint => '••••••••••••';
  String get confirmNewPasswordLabel =>
      isVietnamese ? 'Xác nhận mật khẩu mới' : 'Confirm New Password';
  String get saveChanges =>
      isVietnamese ? 'Lưu thay đổi' : 'Save Changes';

  // ================= EXTRA GETTERS FOR FULL APP =================
  String get hotNewsHOSE =>
      isVietnamese ? 'ĐIỂM NÓNG HOSE' : 'HOSE HIGHLIGHT';
  String get hotNewsHeadline =>
      isVietnamese ? 'Dòng tiền lan tỏa nhóm Bán Lẻ & Công Nghệ' : 'Capital inflows spread to Retail & Tech sectors';
  String get hotNewsSubtitle =>
      isVietnamese ? 'Thanh khoản đạt 18.2K tỷ VNĐ, khối ngoại mua ròng SSI & MWG.' : 'Liquidity hits 18.2T VND, foreign net buy in SSI & MWG.';
  String symbolsCount(int count) =>
      isVietnamese ? '$count mã' : '$count symbols';
  String get colSymbolCompany =>
      isVietnamese ? 'MÃ / DOANH NGHIỆP' : 'SYMBOL / COMPANY';
  String get colTrend =>
      isVietnamese ? 'XU HƯỚNG' : 'TREND';
  String get colMatchChange =>
      isVietnamese ? 'GIÁ KHỚP / +/-' : 'MATCH / +/-';
  String noStocksInCategory(String cat) =>
      isVietnamese ? 'Không có mã cổ phiếu nào thuộc nhóm "$cat"' : 'No stocks found in category "$cat"';
  String get badgeCeiling =>
      isVietnamese ? 'TRẦN' : 'CEIL';
  String get badgeFloor =>
      isVietnamese ? 'SÀN' : 'FLOOR';
  String volumePrefix(String vol) =>
      isVietnamese ? 'KL: $vol' : 'Vol: $vol';

  String get buyAction => isVietnamese ? 'Mua' : 'Buy';
  String get sellAction => isVietnamese ? 'Bán' : 'Sell';
  String get placeOrderTitle => isVietnamese ? 'Đặt lệnh LO' : 'Place LO Order';
  String get txHistoryTitle => transactionHistoryTitle;

  String get orEnterSymbol =>
      isVietnamese ? 'HOẶC TỰ NHẬP MÃ' : 'OR ENTER SYMBOL';
  String get quickSelectFromListed =>
      isVietnamese ? 'Chọn nhanh từ danh mục niêm yết' : 'Quick select from listed stocks';
  String get selectStockPlaceholder =>
      isVietnamese ? '-- Chọn mã cổ phiếu --' : '-- Select stock symbol --';
  String get addedLabel =>
      isVietnamese ? ' (Đã thêm)' : ' (Added)';
  String get enterStockHint =>
      isVietnamese ? 'Nhập mã chứng khoán (VD: FPT, SSI...)' : 'Enter stock symbol (e.g. FPT, SSI...)';
  String get unitThousandDong =>
      isVietnamese ? 'Đơn vị: nghìn đồng' : 'Unit: thousand VND';
  String get actionTradeBuy =>
      isVietnamese ? 'Đặt lệnh mua' : 'Place Buy Order';
  String get actionUnwatch =>
      isVietnamese ? 'Bỏ theo dõi' : 'Unwatch';
  String get btnLater =>
      isVietnamese ? 'Để sau' : 'Later';
  String get btnAdd =>
      isVietnamese ? 'Thêm' : 'Add';

  String get reviewOrderConfirmTitle =>
      isVietnamese ? 'Xác nhận thông tin lệnh' : 'Confirm Order Details';
  String get orderTypeLabel =>
      isVietnamese ? 'Loại lệnh' : 'Order Type';
  String get pricePerQty =>
      isVietnamese ? 'Giá / khối lượng' : 'Price / Quantity';
  String get expectedValue =>
      isVietnamese ? 'Giá trị dự kiến' : 'Estimated Value';
  String get orderDisclaimer =>
      isVietnamese ? 'Lệnh LO sẽ được gửi lên tài khoản đầu tư đang chọn.' : 'LO order will be placed for the selected investment account.';
  String get confirmPlaceOrderBtn =>
      isVietnamese ? 'Xác nhận đặt lệnh' : 'Confirm Order';
  String reviewOrderBtn(bool isBuy) =>
      isVietnamese ? 'Xem lại lệnh ${isBuy ? 'mua' : 'bán'}' : 'Review ${isBuy ? 'Buy' : 'Sell'} Order';
  String get submittingOrder =>
      isVietnamese ? 'Đang gửi lệnh…' : 'Submitting order...';
  String get orderCheckHint =>
      isVietnamese ? 'Lệnh được kiểm tra giá, sức mua và khối lượng trước khi gửi.' : 'Order price, buying power, and quantity are validated before submission.';
  String get orderSuccessSnackbar =>
      isVietnamese ? 'Đã gửi lệnh thành công! Vào Sổ lệnh để theo dõi trạng thái.' : 'Order placed successfully! Check Order Book to track status.';
  String get viewOrderBookAction =>
      isVietnamese ? 'Xem sổ lệnh' : 'View Orders';
  String get latestMatchPrice =>
      isVietnamese ? 'Giá khớp gần nhất' : 'Last Matched Price';
  String get thousandDongUnit =>
      isVietnamese ? 'nghìn ₫' : 'k VND';
  String get tradingAccount =>
      isVietnamese ? 'Tài khoản: ' : 'Account: ';
  String get buyPower =>
      isVietnamese ? 'Sức mua' : 'Buying Power';
  String get available =>
      isVietnamese ? 'Khả dụng' : 'Available';

  String get myOrders =>
      isVietnamese ? 'Lệnh của tôi' : 'My Orders';
  String get openOrdersStat =>
      isVietnamese ? 'Lệnh đang mở' : 'Open Orders';
  String get filledTodayStat =>
      isVietnamese ? 'Đã khớp hôm nay' : 'Filled Today';
  String get viewHistoryBtn =>
      isVietnamese ? 'Lịch sử giao dịch' : 'Transaction History';
  String get noOrdersInStatus =>
      isVietnamese ? 'Không có lệnh trong trạng thái này.' : 'No orders in this status.';
  String get ordersFooterNotice =>
      isVietnamese ? 'Lệnh của tài khoản đang chọn · cập nhật từ máy chủ' : 'Orders for selected account · synced with server';
  String orderIdToday(String id, String time) =>
      isVietnamese ? '$id  ·  Hôm nay, $time' : '$id  ·  Today, $time';
  String get filledQty =>
      isVietnamese ? 'ĐÃ KHỚP' : 'FILLED';

  String get transactionsFooterNotice =>
      isVietnamese ? 'Dữ liệu giao dịch khớp lệnh thực tế từ sở giao dịch' : 'Actual trade execution data from exchange';
  String get totalTradeValue =>
      isVietnamese ? 'Tổng giá trị giao dịch' : 'Total Trade Value';

  String get candleChartTitle =>
      isVietnamese ? 'Biểu đồ nến' : 'Candle Chart';
  String get tradeInfoTitle =>
      isVietnamese ? 'Thông tin giao dịch' : 'Trading Info';
  String get sessionPricesTitle =>
      isVietnamese ? 'Giá trong phiên' : 'Intraday Depth';
  String get openPrice =>
      isVietnamese ? 'Mở cửa' : 'Open';
  String get highPrice =>
      isVietnamese ? 'Cao nhất' : 'High';
  String get lowPrice =>
      isVietnamese ? 'Thấp nhất' : 'Low';
  String get depthTapHint =>
      isVietnamese ? 'Chạm vào mức giá để điền nhanh vào màn hình Đặt lệnh' : 'Tap any price level to autofill Order screen';
  String get bidQty =>
      isVietnamese ? 'KL MUA' : 'BID VOL';
  String get bidPrice =>
      isVietnamese ? 'GIÁ MUA' : 'BID';
  String get askPrice =>
      isVietnamese ? 'GIÁ BÁN' : 'ASK';
  String get askQty =>
      isVietnamese ? 'KL BÁN' : 'ASK VOL';
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
