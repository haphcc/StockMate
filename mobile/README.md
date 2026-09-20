# StockMate — Mobile app (Flutter + Dart)

Khung thư mục cho app giao dịch chứng khoán chạy trên **Android + iOS**.
Hiện tại mới có cấu trúc thư mục và file cấu hình; phần code sẽ viết sau.

## 1. Sinh 2 thư mục native `android/` và `ios/`

Máy dựng khung này chưa cài Flutter SDK nên chưa sinh được phần native.
Sau khi cài Flutter, chạy đúng 1 lệnh sau tại thư mục `mobile/`:

```bash
flutter create --platforms=android,ios --org vn.stockmate --project-name stockmate .
flutter pub get
```

Lệnh này tạo `android/`, `ios/`, `lib/main.dart` từ template chính thức mà
không đụng tới các thư mục đã có. Nếu `pubspec.yaml` bị ghi đè, khôi phục bằng:

```bash
git checkout -- pubspec.yaml
```

Kiểm tra môi trường và chạy thử:

```bash
flutter doctor            # bắt buộc xanh ở mục Android toolchain / Xcode
flutter devices
flutter run               # chọn emulator Android hoặc iOS simulator
```

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

## 4. Việc cần làm ở phần native sau khi `flutter create`

**Android** — `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
```
`android/app/build.gradle`: đặt `minSdk = 23` (yêu cầu của `flutter_secure_storage`).

**iOS** — `ios/Runner/Info.plist`: đặt `CFBundleDisplayName` là `StockMate`.
Khi test với backend chạy HTTP ở localhost, thêm tạm `NSAppTransportSecurity`
→ `NSAllowsLocalNetworking = true` (production phải dùng HTTPS).

## 5. Kết nối với backend

Base URL mặc định khi chạy máy ảo: Android emulator `http://10.0.2.2:8000`,
iOS simulator `http://localhost:8000`. Khi chạy với server thật:

```bash
flutter run --dart-define=API_BASE_URL=https://api.stockmate.vn
```

Schema và dữ liệu mẫu của backend nằm ở `../data/postgres/` (xem `../data/README.md`).
