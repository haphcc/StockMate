# StockMate — Mobile app (Flutter + Dart)

Khung thư mục cho app giao dịch chứng khoán chạy trên **Android + iOS**.
Hiện tại mới có cấu trúc thư mục và file cấu hình; phần code sẽ viết sau.

## 1. Trạng thái dự án

`android/` và `ios/` đã được sinh sẵn bằng:

```bash
flutter create --platforms=android,ios --org vn.stockmate --project-name stockmate .
```

Đã chạy và pass trên Flutter 3.47.5 / Dart 3.13.4:

```bash
flutter pub get     # OK
flutter analyze     # No issues found!
flutter test        # All tests passed (test mẫu của template)
```

`lib/main.dart` và `test/widget_test.dart` hiện là bản mẫu của Flutter, sẽ thay khi vào code thật.

Chạy app:

```bash
flutter devices
flutter run                 # chọn emulator Android / iOS simulator
```

> **Cần cài thêm:** `flutter doctor` báo thiếu **Android SDK** nên chưa build được APK
> (`flutter build apk` dừng với `No Android SDK found`). Cài Android Studio
> (kèm SDK + emulator), rồi `flutter doctor --android-licenses`.
> Build iOS bắt buộc máy macOS + Xcode.

## 2. Cấu trúc thư mục

```
mobile/
├── android/                 # sinh bằng flutter create
├── ios/                     # sinh bằng flutter create
├── assets/
│   ├── fonts/               # font tiếng Việt (khai báo thêm trong pubspec.yaml)
│   ├── icons/
│   └── images/
├── lib/
│   ├── core/                # phần dùng chung toàn app
│   │   ├── config/          # AppConfig: base URL API theo môi trường
│   │   ├── constants/       # hằng số: loại lệnh, trạng thái, sàn HOSE/HNX/UPCOM
│   │   ├── network/         # Dio client, interceptor JWT, ApiEndpoints, ApiException
│   │   ├── router/          # go_router: khai báo route + guard đăng nhập
│   │   ├── storage/         # flutter_secure_storage: lưu access/refresh token
│   │   ├── theme/           # màu bảng giá (trần/sàn/tham chiếu/tăng/giảm), ThemeData
│   │   ├── utils/           # format tiền VND, %, ngày giờ, validator
│   │   └── widgets/         # widget dùng lại: loading, empty, error, price text
│   ├── data/
│   │   ├── datasources/     # gọi API thô theo từng nhóm endpoint
│   │   ├── models/          # model map với bảng/view của PostgreSQL
│   │   └── repositories/    # gộp datasource + cache, tầng app gọi vào đây
│   ├── features/            # chia theo màn hình nghiệp vụ
│   │   ├── auth/            # đăng nhập, đăng ký, eKYC
│   │   ├── home/            # khung bottom navigation
│   │   ├── market/          # bảng giá, chi tiết mã, biểu đồ nến
│   │   ├── order/           # đặt lệnh mua/bán, sổ lệnh
│   │   ├── portfolio/       # danh mục, tài sản, lãi/lỗ
│   │   ├── transaction/     # lịch sử giao dịch
│   │   ├── watchlist/       # danh mục quan tâm
│   │   ├── notification/    # thông báo
│   │   └── profile/         # tài khoản cá nhân, cài đặt
│   │       (mỗi feature: screens/ · widgets/ · providers/)
│   ├── l10n/                # đa ngôn ngữ vi_VN / en_US
│   ├── providers/           # provider dùng chung (Riverpod): dio, auth state...
│   └── main.dart            # sinh bằng flutter create
└── test/
    ├── unit/
    └── widget/
```

Mỗi thư mục có file `.gitkeep` để git theo dõi được thư mục rỗng; xoá file này
khi đã có code thật trong thư mục.

## 3. Thư viện đã khai báo trong `pubspec.yaml`

| Gói | Dùng để |
|---|---|
| `flutter_riverpod` | Quản lý state |
| `go_router` | Điều hướng, guard màn hình cần đăng nhập |
| `dio` | Gọi REST API của FastAPI |
| `flutter_secure_storage` | Lưu JWT an toàn (Keychain / EncryptedSharedPreferences) |
| `shared_preferences` | Lưu tuỳ chọn người dùng |
| `fl_chart` | Biểu đồ giá / biểu đồ nến |
| `intl` | Định dạng số tiền, ngày giờ theo `vi_VN` |
| `equatable` | So sánh model |

Chạy `flutter pub get` sau khi tạo xong phần native.

## 4. Cấu hình native đã áp dụng

**Android** (`android/app/src/main/AndroidManifest.xml`)
- thêm quyền `android.permission.INTERNET` để gọi API
- `android:label` = `StockMate`
- `applicationId` / namespace: `vn.stockmate.stockmate`
- `minSdk` giữ mặc định của Flutter (**24**) — đã đủ cho `flutter_secure_storage` 11.x

**iOS** (`ios/Runner/Info.plist`)
- `CFBundleDisplayName` = `StockMate`
- `NSAppTransportSecurity` → `NSAllowsLocalNetworking = true` để gọi backend HTTP
  trong mạng nội bộ lúc dev. **Production phải dùng HTTPS và bỏ khoá này.**

Còn phải làm trước khi phát hành: ký APK release (`android/key.properties`,
hiện release đang ký bằng debug key) và cấu hình signing team trong Xcode.

## 5. Kết nối với backend

Base URL mặc định khi chạy máy ảo: Android emulator `http://10.0.2.2:8000`,
iOS simulator `http://localhost:8000`. Khi chạy với server thật:

```bash
flutter run --dart-define=API_BASE_URL=https://api.stockmate.vn
```

Schema và dữ liệu mẫu của backend nằm ở `../data/postgres/` (xem `../data/README.md`).
