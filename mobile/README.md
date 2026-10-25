# StockMate — Mobile app (Flutter + Dart)

App Flutter chạy trên **Android + iOS**, đã có UI auth/dashboard/order/portfolio dùng mock.
API repository và các feature TODO chưa triển khai. Hướng dẫn hiện hành:
[START_HERE](../docs/START_HERE.md), [SETUP](../docs/SETUP.md), [API_CONTRACT](../docs/API_CONTRACT.md).
Sơn theo [TV2](../docs/team/TV2_SON.md), Me theo [TV3](../docs/team/TV3_ME.md).

## 1. Trạng thái dự án

`android/` và `ios/` đã được sinh sẵn bằng:

```bash
flutter create --platforms=android,ios --org vn.stockmate --project-name stockmate .
```

Chuẩn nhóm Flutter 3.47.5 / Dart >=3.13 theo lock. Chạy lại để kiểm tra checkout hiện tại:

```bash
flutter pub get
flutter analyze
flutter test
```

`lib/main.dart` đã dùng Riverpod + GoRouter; test hiện là smoke test khởi tạo app.
Chưa có kiểm chứng E2E API thật. File chỉ có comment TODO là vị trí bàn giao, không phải feature đã xong.

Chạy app:

```bash
flutter devices
flutter run                 # chọn emulator Android / iOS simulator
```

> Kiểm tra SDK trên từng máy bằng `flutter doctor`. Máy thiếu Android SDK cần cài Android Studio
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

Base URL mặc định trong code là Android emulator `http://10.0.2.2:8000`.
iOS simulator phải override `http://localhost:8000`. Code gốc hiện có useMock=true cố định;
Sơn tự thêm đọc USE_MOCK trong FE-02. Sau khi hoàn thành FE-02 và BE-01/02 mới dùng lệnh dưới:

```bash
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Schema và dữ liệu mẫu của backend nằm ở `../data/postgres/` (xem `../data/README.md`).
