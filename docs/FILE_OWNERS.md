# Ai phụ trách từng file

Nguồn máy đọc: FILE_OWNERS.json; quy tắc khớp đầu tiên có hiệu lực.
Một file có một chủ chính; người khác vẫn có thể đề xuất sửa bằng PR phối hợp.
Chủ file chịu trách nhiệm tích hợp/review, không phải cơ chế khóa file của GitHub.

Tên Me là thành viên TV3, không phải đại từ tôi hoặc người yêu cầu chuẩn bị repo.

Không có GitHub username của nhóm nên chưa tạo CODEOWNERS giả.
Phuoc thêm username thật sau và cấu hình branch protection nếu nhóm dùng GitHub.

## File chung cần phối hợp

| File/nhóm | Chủ chính | Ai cần cùng kiểm tra |
|---|---|---|
| Schema/OpenAPI/examples | LB; trading schema: Tuệ | Sơn, Me (TV3), Châu |
| Migration/SQL | Phuoc | Tuệ (luật), LB (mapping), Châu (regression) |
| Router/providers/network/shared models | Sơn | Me (TV3) đề xuất thay đổi qua cùng PR |
| MarketRepository hiện có | Sơn | Me (TV3) dùng để đọc thị trường; phối hợp nếu thêm method |
| Pubspec/lock/theme/assets | Sơn | Me (TV3) dùng lại, không tự tạo bộ theme thứ hai |
| Tests integration/E2E | Châu | Người viết tính năng cung cấp fixture và điều kiện test |

## Tra cứu nhanh

`python scripts/check_preparation.py --owner TV2` để in file của Sơn.
Sau khi tạo file: `python scripts/check_preparation.py --write-owners`.
Dòng 'TODO' trong source là file khung, chưa có tính năng.

## TV1 — Phuoc — DB, DevOps, integration order

| File |
|---|
| [.dockerignore](../.dockerignore) |
| [.github/workflows/checks.yml](../.github/workflows/checks.yml) |
| [.gitignore](../.gitignore) |
| [README.md](../README.md) |
| [backend/Dockerfile](../backend/Dockerfile) |
| [backend/alembic.ini](../backend/alembic.ini) |
| [backend/alembic/env.py](../backend/alembic/env.py) |
| [backend/alembic/script.py.mako](../backend/alembic/script.py.mako) |
| [backend/alembic/sql/0001_functions.sql](../backend/alembic/sql/0001_functions.sql) |
| [backend/alembic/sql/0001_schema.sql](../backend/alembic/sql/0001_schema.sql) |
| [backend/alembic/sql/0001_views.sql](../backend/alembic/sql/0001_views.sql) |
| [backend/alembic/versions/.gitkeep](../backend/alembic/versions/.gitkeep) |
| [backend/alembic/versions/0001_baseline.py](../backend/alembic/versions/0001_baseline.py) |
| [backend/scripts/seed_demo.py](../backend/scripts/seed_demo.py) |
| [compose.yaml](../compose.yaml) |
| [data/README.md](../data/README.md) |
| [data/postgres/00_run_all.sql](../data/postgres/00_run_all.sql) |
| [data/postgres/01_schema.sql](../data/postgres/01_schema.sql) |
| [data/postgres/02_functions_triggers.sql](../data/postgres/02_functions_triggers.sql) |
| [data/postgres/03_seed_stocks.sql](../data/postgres/03_seed_stocks.sql) |
| [data/postgres/04_seed_customers.sql](../data/postgres/04_seed_customers.sql) |
| [data/postgres/05_seed_trading.sql](../data/postgres/05_seed_trading.sql) |
| [data/postgres/06_seed_price_history.sql](../data/postgres/06_seed_price_history.sql) |
| [data/postgres/07_seed_notifications.sql](../data/postgres/07_seed_notifications.sql) |
| [data/postgres/08_views.sql](../data/postgres/08_views.sql) |
| [docs/BUSINESS_RULES.md](../docs/BUSINESS_RULES.md) |
| [docs/DATABASE_WORKFLOW.md](../docs/DATABASE_WORKFLOW.md) |
| [docs/FILE_OWNERS.json](../docs/FILE_OWNERS.json) |
| [docs/FILE_OWNERS.md](../docs/FILE_OWNERS.md) |
| [docs/MVP_SCOPE.md](../docs/MVP_SCOPE.md) |
| [docs/PLAN.md](../docs/PLAN.md) |
| [docs/PROJECT_STRUCTURE.md](../docs/PROJECT_STRUCTURE.md) |
| [docs/SETUP.md](../docs/SETUP.md) |
| [docs/START_HERE.md](../docs/START_HERE.md) |
| [docs/TASK_ASSIGNMENT.md](../docs/TASK_ASSIGNMENT.md) |
| [docs/team/TV1_PHUOC.md](../docs/team/TV1_PHUOC.md) |
| [mobile/android/.gitignore](../mobile/android/.gitignore) |
| [mobile/android/.kotlin/errors/errors-1790959595256.log](../mobile/android/.kotlin/errors/errors-1790959595256.log) |
| [mobile/android/.kotlin/errors/errors-1791012559848.log](../mobile/android/.kotlin/errors/errors-1791012559848.log) |
| [mobile/android/app/build.gradle.kts](../mobile/android/app/build.gradle.kts) |
| [mobile/android/app/src/main/AndroidManifest.xml](../mobile/android/app/src/main/AndroidManifest.xml) |
| [mobile/android/app/src/main/kotlin/vn/stockmate/stockmate/MainActivity.kt](../mobile/android/app/src/main/kotlin/vn/stockmate/stockmate/MainActivity.kt) |
| [mobile/android/app/src/main/res/drawable-v21/launch_background.xml](../mobile/android/app/src/main/res/drawable-v21/launch_background.xml) |
| [mobile/android/app/src/main/res/drawable/launch_background.xml](../mobile/android/app/src/main/res/drawable/launch_background.xml) |
| [mobile/android/app/src/main/res/mipmap-hdpi/ic_launcher.png](../mobile/android/app/src/main/res/mipmap-hdpi/ic_launcher.png) |
| [mobile/android/app/src/main/res/mipmap-mdpi/ic_launcher.png](../mobile/android/app/src/main/res/mipmap-mdpi/ic_launcher.png) |
| [mobile/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png](../mobile/android/app/src/main/res/mipmap-xhdpi/ic_launcher.png) |
| [mobile/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png](../mobile/android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png) |
| [mobile/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png](../mobile/android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png) |
| [mobile/android/app/src/main/res/values-night/styles.xml](../mobile/android/app/src/main/res/values-night/styles.xml) |
| [mobile/android/app/src/main/res/values/styles.xml](../mobile/android/app/src/main/res/values/styles.xml) |
| [mobile/android/app/src/profile/AndroidManifest.xml](../mobile/android/app/src/profile/AndroidManifest.xml) |
| [mobile/android/build.gradle.kts](../mobile/android/build.gradle.kts) |
| [mobile/android/gradle.properties](../mobile/android/gradle.properties) |
| [mobile/android/gradle/wrapper/gradle-wrapper.properties](../mobile/android/gradle/wrapper/gradle-wrapper.properties) |
| [mobile/android/settings.gradle.kts](../mobile/android/settings.gradle.kts) |
| [mobile/ios/.gitignore](../mobile/ios/.gitignore) |
| [mobile/ios/Flutter/AppFrameworkInfo.plist](../mobile/ios/Flutter/AppFrameworkInfo.plist) |
| [mobile/ios/Flutter/Debug.xcconfig](../mobile/ios/Flutter/Debug.xcconfig) |
| [mobile/ios/Flutter/Release.xcconfig](../mobile/ios/Flutter/Release.xcconfig) |
| [mobile/ios/Runner.xcodeproj/project.pbxproj](../mobile/ios/Runner.xcodeproj/project.pbxproj) |
| [mobile/ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata](../mobile/ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata) |
| [mobile/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist](../mobile/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist) |
| [mobile/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings](../mobile/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings) |
| [mobile/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme](../mobile/ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme) |
| [mobile/ios/Runner.xcworkspace/contents.xcworkspacedata](../mobile/ios/Runner.xcworkspace/contents.xcworkspacedata) |
| [mobile/ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist](../mobile/ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist) |
| [mobile/ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings](../mobile/ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings) |
| [mobile/ios/Runner/AppDelegate.swift](../mobile/ios/Runner/AppDelegate.swift) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png) |
| [mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png](../mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png) |
| [mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json](../mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json) |
| [mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png](../mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png) |
| [mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png](../mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png) |
| [mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png](../mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png) |
| [mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md](../mobile/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md) |
| [mobile/ios/Runner/Base.lproj/LaunchScreen.storyboard](../mobile/ios/Runner/Base.lproj/LaunchScreen.storyboard) |
| [mobile/ios/Runner/Base.lproj/Main.storyboard](../mobile/ios/Runner/Base.lproj/Main.storyboard) |
| [mobile/ios/Runner/Runner-Bridging-Header.h](../mobile/ios/Runner/Runner-Bridging-Header.h) |
| [mobile/ios/Runner/SceneDelegate.swift](../mobile/ios/Runner/SceneDelegate.swift) |
| [mobile/ios/RunnerTests/RunnerTests.swift](../mobile/ios/RunnerTests/RunnerTests.swift) |
| [mobile/web/favicon.png](../mobile/web/favicon.png) |
| [mobile/web/icons/Icon-192.png](../mobile/web/icons/Icon-192.png) |
| [mobile/web/icons/Icon-512.png](../mobile/web/icons/Icon-512.png) |
| [mobile/web/icons/Icon-maskable-192.png](../mobile/web/icons/Icon-maskable-192.png) |
| [mobile/web/icons/Icon-maskable-512.png](../mobile/web/icons/Icon-maskable-512.png) |
| [mobile/web/index.html](../mobile/web/index.html) |
| [mobile/web/manifest.json](../mobile/web/manifest.json) |

## TV2 — Sơn — Flutter foundation, auth, dashboard, portfolio

| File |
|---|
| [docs/team/TV2_SON.md](../docs/team/TV2_SON.md) |
| [mobile/.gitignore](../mobile/.gitignore) |
| [mobile/README.md](../mobile/README.md) |
| [mobile/analysis_options.yaml](../mobile/analysis_options.yaml) |
| [mobile/android/app/src/debug/AndroidManifest.xml](../mobile/android/app/src/debug/AndroidManifest.xml) |
| [mobile/assets/fonts/.gitkeep](../mobile/assets/fonts/.gitkeep) |
| [mobile/assets/icons/.gitkeep](../mobile/assets/icons/.gitkeep) |
| [mobile/assets/icons/app_icon.png](../mobile/assets/icons/app_icon.png) |
| [mobile/assets/icons/my_apple_icon.png](../mobile/assets/icons/my_apple_icon.png) |
| [mobile/assets/icons/my_google_icon.png](../mobile/assets/icons/my_google_icon.png) |
| [mobile/assets/images/.gitkeep](../mobile/assets/images/.gitkeep) |
| [mobile/assets/images/app_logo.png](../mobile/assets/images/app_logo.png) |
| [mobile/ios/Runner/Info.plist](../mobile/ios/Runner/Info.plist) |
| [mobile/lib/core/config/.gitkeep](../mobile/lib/core/config/.gitkeep) |
| [mobile/lib/core/config/app_config.dart](../mobile/lib/core/config/app_config.dart) |
| [mobile/lib/core/constants/.gitkeep](../mobile/lib/core/constants/.gitkeep) |
| [mobile/lib/core/network/.gitkeep](../mobile/lib/core/network/.gitkeep) |
| [mobile/lib/core/network/api_endpoints.dart](../mobile/lib/core/network/api_endpoints.dart) |
| [mobile/lib/core/network/api_exception.dart](../mobile/lib/core/network/api_exception.dart) |
| [mobile/lib/core/network/dio_client.dart](../mobile/lib/core/network/dio_client.dart) |
| [mobile/lib/core/router/.gitkeep](../mobile/lib/core/router/.gitkeep) |
| [mobile/lib/core/router/app_router.dart](../mobile/lib/core/router/app_router.dart) |
| [mobile/lib/core/storage/.gitkeep](../mobile/lib/core/storage/.gitkeep) |
| [mobile/lib/core/storage/token_storage.dart](../mobile/lib/core/storage/token_storage.dart) |
| [mobile/lib/core/theme/.gitkeep](../mobile/lib/core/theme/.gitkeep) |
| [mobile/lib/core/theme/app_colors.dart](../mobile/lib/core/theme/app_colors.dart) |
| [mobile/lib/core/theme/app_theme.dart](../mobile/lib/core/theme/app_theme.dart) |
| [mobile/lib/core/theme/price_colors.dart](../mobile/lib/core/theme/price_colors.dart) |
| [mobile/lib/core/utils/.gitkeep](../mobile/lib/core/utils/.gitkeep) |
| [mobile/lib/core/utils/formatters.dart](../mobile/lib/core/utils/formatters.dart) |
| [mobile/lib/core/utils/money.dart](../mobile/lib/core/utils/money.dart) |
| [mobile/lib/core/utils/validators.dart](../mobile/lib/core/utils/validators.dart) |
| [mobile/lib/core/widgets/.gitkeep](../mobile/lib/core/widgets/.gitkeep) |
| [mobile/lib/core/widgets/app_text_field.dart](../mobile/lib/core/widgets/app_text_field.dart) |
| [mobile/lib/core/widgets/empty_state.dart](../mobile/lib/core/widgets/empty_state.dart) |
| [mobile/lib/core/widgets/error_state.dart](../mobile/lib/core/widgets/error_state.dart) |
| [mobile/lib/core/widgets/exchange_chip.dart](../mobile/lib/core/widgets/exchange_chip.dart) |
| [mobile/lib/core/widgets/glass_card.dart](../mobile/lib/core/widgets/glass_card.dart) |
| [mobile/lib/core/widgets/gradient_button.dart](../mobile/lib/core/widgets/gradient_button.dart) |
| [mobile/lib/core/widgets/price_text.dart](../mobile/lib/core/widgets/price_text.dart) |
| [mobile/lib/core/widgets/shimmer_box.dart](../mobile/lib/core/widgets/shimmer_box.dart) |
| [mobile/lib/core/widgets/sparkline_chart.dart](../mobile/lib/core/widgets/sparkline_chart.dart) |
| [mobile/lib/core/widgets/stockmate_brand.dart](../mobile/lib/core/widgets/stockmate_brand.dart) |
| [mobile/lib/data/datasources/.gitkeep](../mobile/lib/data/datasources/.gitkeep) |
| [mobile/lib/data/datasources/auth_datasource.dart](../mobile/lib/data/datasources/auth_datasource.dart) |
| [mobile/lib/data/datasources/market_datasource.dart](../mobile/lib/data/datasources/market_datasource.dart) |
| [mobile/lib/data/models/.gitkeep](../mobile/lib/data/models/.gitkeep) |
| [mobile/lib/data/models/account_model.dart](../mobile/lib/data/models/account_model.dart) |
| [mobile/lib/data/models/portfolio_model.dart](../mobile/lib/data/models/portfolio_model.dart) |
| [mobile/lib/data/models/user_model.dart](../mobile/lib/data/models/user_model.dart) |
| [mobile/lib/data/repositories/.gitkeep](../mobile/lib/data/repositories/.gitkeep) |
| [mobile/lib/data/repositories/api_auth_repository.dart](../mobile/lib/data/repositories/api_auth_repository.dart) |
| [mobile/lib/data/repositories/api_market_repository.dart](../mobile/lib/data/repositories/api_market_repository.dart) |
| [mobile/lib/data/repositories/auth_repository.dart](../mobile/lib/data/repositories/auth_repository.dart) |
| [mobile/lib/data/repositories/market_repository.dart](../mobile/lib/data/repositories/market_repository.dart) |
| [mobile/lib/data/repositories/mock_auth_repository.dart](../mobile/lib/data/repositories/mock_auth_repository.dart) |
| [mobile/lib/data/repositories/mock_market_repository.dart](../mobile/lib/data/repositories/mock_market_repository.dart) |
| [mobile/lib/features/auth/providers/.gitkeep](../mobile/lib/features/auth/providers/.gitkeep) |
| [mobile/lib/features/auth/providers/auth_provider.dart](../mobile/lib/features/auth/providers/auth_provider.dart) |
| [mobile/lib/features/auth/screens/.gitkeep](../mobile/lib/features/auth/screens/.gitkeep) |
| [mobile/lib/features/auth/screens/login_screen.dart](../mobile/lib/features/auth/screens/login_screen.dart) |
| [mobile/lib/features/auth/screens/register_screen.dart](../mobile/lib/features/auth/screens/register_screen.dart) |
| [mobile/lib/features/auth/screens/splash_screen.dart](../mobile/lib/features/auth/screens/splash_screen.dart) |
| [mobile/lib/features/auth/widgets/.gitkeep](../mobile/lib/features/auth/widgets/.gitkeep) |
| [mobile/lib/features/auth/widgets/social_login_buttons.dart](../mobile/lib/features/auth/widgets/social_login_buttons.dart) |
| [mobile/lib/features/home/providers/dashboard_provider.dart](../mobile/lib/features/home/providers/dashboard_provider.dart) |
| [mobile/lib/features/home/screens/.gitkeep](../mobile/lib/features/home/screens/.gitkeep) |
| [mobile/lib/features/home/screens/dashboard_screen.dart](../mobile/lib/features/home/screens/dashboard_screen.dart) |
| [mobile/lib/features/home/screens/home_shell.dart](../mobile/lib/features/home/screens/home_shell.dart) |
| [mobile/lib/features/home/widgets/.gitkeep](../mobile/lib/features/home/widgets/.gitkeep) |
| [mobile/lib/features/portfolio/providers/.gitkeep](../mobile/lib/features/portfolio/providers/.gitkeep) |
| [mobile/lib/features/portfolio/providers/portfolio_provider.dart](../mobile/lib/features/portfolio/providers/portfolio_provider.dart) |
| [mobile/lib/features/portfolio/screens/.gitkeep](../mobile/lib/features/portfolio/screens/.gitkeep) |
| [mobile/lib/features/portfolio/screens/portfolio_screen.dart](../mobile/lib/features/portfolio/screens/portfolio_screen.dart) |
| [mobile/lib/features/portfolio/widgets/.gitkeep](../mobile/lib/features/portfolio/widgets/.gitkeep) |
| [mobile/lib/features/profile/screens/.gitkeep](../mobile/lib/features/profile/screens/.gitkeep) |
| [mobile/lib/features/profile/widgets/.gitkeep](../mobile/lib/features/profile/widgets/.gitkeep) |
| [mobile/lib/l10n/.gitkeep](../mobile/lib/l10n/.gitkeep) |
| [mobile/lib/main.dart](../mobile/lib/main.dart) |
| [mobile/lib/providers/.gitkeep](../mobile/lib/providers/.gitkeep) |
| [mobile/lib/providers/app_providers.dart](../mobile/lib/providers/app_providers.dart) |
| [mobile/lib/providers/selected_account_provider.dart](../mobile/lib/providers/selected_account_provider.dart) |
| [mobile/pubspec.lock](../mobile/pubspec.lock) |
| [mobile/pubspec.yaml](../mobile/pubspec.yaml) |
| [mobile/test/widget_test.dart](../mobile/test/widget_test.dart) |

## TV3 — Me — Flutter market, watchlist, trading, notifications

| File |
|---|
| [docs/team/TV3_ME.md](../docs/team/TV3_ME.md) |
| [mobile/lib/data/datasources/notification_datasource.dart](../mobile/lib/data/datasources/notification_datasource.dart) |
| [mobile/lib/data/datasources/trading_datasource.dart](../mobile/lib/data/datasources/trading_datasource.dart) |
| [mobile/lib/data/datasources/watchlist_datasource.dart](../mobile/lib/data/datasources/watchlist_datasource.dart) |
| [mobile/lib/data/models/candle_model.dart](../mobile/lib/data/models/candle_model.dart) |
| [mobile/lib/data/models/notification_model.dart](../mobile/lib/data/models/notification_model.dart) |
| [mobile/lib/data/models/order_model.dart](../mobile/lib/data/models/order_model.dart) |
| [mobile/lib/data/models/stock_model.dart](../mobile/lib/data/models/stock_model.dart) |
| [mobile/lib/data/models/transaction_model.dart](../mobile/lib/data/models/transaction_model.dart) |
| [mobile/lib/data/repositories/notification_repository.dart](../mobile/lib/data/repositories/notification_repository.dart) |
| [mobile/lib/data/repositories/trading_repository.dart](../mobile/lib/data/repositories/trading_repository.dart) |
| [mobile/lib/data/repositories/watchlist_repository.dart](../mobile/lib/data/repositories/watchlist_repository.dart) |
| [mobile/lib/features/market/providers/.gitkeep](../mobile/lib/features/market/providers/.gitkeep) |
| [mobile/lib/features/market/providers/market_provider.dart](../mobile/lib/features/market/providers/market_provider.dart) |
| [mobile/lib/features/market/screens/.gitkeep](../mobile/lib/features/market/screens/.gitkeep) |
| [mobile/lib/features/market/screens/market_board_screen.dart](../mobile/lib/features/market/screens/market_board_screen.dart) |
| [mobile/lib/features/market/screens/stock_detail_screen.dart](../mobile/lib/features/market/screens/stock_detail_screen.dart) |
| [mobile/lib/features/market/widgets/.gitkeep](../mobile/lib/features/market/widgets/.gitkeep) |
| [mobile/lib/features/notification/providers/.gitkeep](../mobile/lib/features/notification/providers/.gitkeep) |
| [mobile/lib/features/notification/providers/notification_provider.dart](../mobile/lib/features/notification/providers/notification_provider.dart) |
| [mobile/lib/features/notification/screens/.gitkeep](../mobile/lib/features/notification/screens/.gitkeep) |
| [mobile/lib/features/notification/screens/notification_screen.dart](../mobile/lib/features/notification/screens/notification_screen.dart) |
| [mobile/lib/features/order/providers/.gitkeep](../mobile/lib/features/order/providers/.gitkeep) |
| [mobile/lib/features/order/providers/order_provider.dart](../mobile/lib/features/order/providers/order_provider.dart) |
| [mobile/lib/features/order/screens/.gitkeep](../mobile/lib/features/order/screens/.gitkeep) |
| [mobile/lib/features/order/screens/order_book_screen.dart](../mobile/lib/features/order/screens/order_book_screen.dart) |
| [mobile/lib/features/order/screens/place_order_screen.dart](../mobile/lib/features/order/screens/place_order_screen.dart) |
| [mobile/lib/features/order/widgets/.gitkeep](../mobile/lib/features/order/widgets/.gitkeep) |
| [mobile/lib/features/transaction/providers/.gitkeep](../mobile/lib/features/transaction/providers/.gitkeep) |
| [mobile/lib/features/transaction/providers/transaction_provider.dart](../mobile/lib/features/transaction/providers/transaction_provider.dart) |
| [mobile/lib/features/transaction/screens/.gitkeep](../mobile/lib/features/transaction/screens/.gitkeep) |
| [mobile/lib/features/transaction/screens/transaction_history_screen.dart](../mobile/lib/features/transaction/screens/transaction_history_screen.dart) |
| [mobile/lib/features/transaction/widgets/.gitkeep](../mobile/lib/features/transaction/widgets/.gitkeep) |
| [mobile/lib/features/watchlist/providers/.gitkeep](../mobile/lib/features/watchlist/providers/.gitkeep) |
| [mobile/lib/features/watchlist/providers/watchlist_provider.dart](../mobile/lib/features/watchlist/providers/watchlist_provider.dart) |
| [mobile/lib/features/watchlist/screens/.gitkeep](../mobile/lib/features/watchlist/screens/.gitkeep) |
| [mobile/lib/features/watchlist/screens/watchlist_screen.dart](../mobile/lib/features/watchlist/screens/watchlist_screen.dart) |
| [mobile/lib/features/watchlist/widgets/.gitkeep](../mobile/lib/features/watchlist/widgets/.gitkeep) |

## TV4 — LB — Backend foundation, auth, market, accounts

| File |
|---|
| [backend/.env.example](../backend/.env.example) |
| [backend/.gitignore](../backend/.gitignore) |
| [backend/README.md](../backend/README.md) |
| [backend/app/__init__.py](../backend/app/__init__.py) |
| [backend/app/api/.gitkeep](../backend/app/api/.gitkeep) |
| [backend/app/api/__init__.py](../backend/app/api/__init__.py) |
| [backend/app/api/deps.py](../backend/app/api/deps.py) |
| [backend/app/api/v1/__init__.py](../backend/app/api/v1/__init__.py) |
| [backend/app/api/v1/api.py](../backend/app/api/v1/api.py) |
| [backend/app/api/v1/endpoints/.gitkeep](../backend/app/api/v1/endpoints/.gitkeep) |
| [backend/app/api/v1/endpoints/__init__.py](../backend/app/api/v1/endpoints/__init__.py) |
| [backend/app/api/v1/endpoints/accounts.py](../backend/app/api/v1/endpoints/accounts.py) |
| [backend/app/api/v1/endpoints/auth.py](../backend/app/api/v1/endpoints/auth.py) |
| [backend/app/api/v1/endpoints/health.py](../backend/app/api/v1/endpoints/health.py) |
| [backend/app/api/v1/endpoints/market.py](../backend/app/api/v1/endpoints/market.py) |
| [backend/app/api/v1/endpoints/watchlist.py](../backend/app/api/v1/endpoints/watchlist.py) |
| [backend/app/core/.gitkeep](../backend/app/core/.gitkeep) |
| [backend/app/core/__init__.py](../backend/app/core/__init__.py) |
| [backend/app/core/config.py](../backend/app/core/config.py) |
| [backend/app/core/errors.py](../backend/app/core/errors.py) |
| [backend/app/core/security.py](../backend/app/core/security.py) |
| [backend/app/crud/.gitkeep](../backend/app/crud/.gitkeep) |
| [backend/app/crud/__init__.py](../backend/app/crud/__init__.py) |
| [backend/app/crud/accounts.py](../backend/app/crud/accounts.py) |
| [backend/app/crud/auth.py](../backend/app/crud/auth.py) |
| [backend/app/crud/market.py](../backend/app/crud/market.py) |
| [backend/app/crud/watchlist.py](../backend/app/crud/watchlist.py) |
| [backend/app/db/.gitkeep](../backend/app/db/.gitkeep) |
| [backend/app/db/__init__.py](../backend/app/db/__init__.py) |
| [backend/app/db/base.py](../backend/app/db/base.py) |
| [backend/app/db/session.py](../backend/app/db/session.py) |
| [backend/app/main.py](../backend/app/main.py) |
| [backend/app/models/.gitkeep](../backend/app/models/.gitkeep) |
| [backend/app/models/__init__.py](../backend/app/models/__init__.py) |
| [backend/app/models/customer.py](../backend/app/models/customer.py) |
| [backend/app/models/investment_account.py](../backend/app/models/investment_account.py) |
| [backend/app/models/portfolio.py](../backend/app/models/portfolio.py) |
| [backend/app/models/stock.py](../backend/app/models/stock.py) |
| [backend/app/models/stock_price_history.py](../backend/app/models/stock_price_history.py) |
| [backend/app/models/watchlist.py](../backend/app/models/watchlist.py) |
| [backend/app/schemas/.gitkeep](../backend/app/schemas/.gitkeep) |
| [backend/app/schemas/__init__.py](../backend/app/schemas/__init__.py) |
| [backend/app/schemas/accounts.py](../backend/app/schemas/accounts.py) |
| [backend/app/schemas/auth.py](../backend/app/schemas/auth.py) |
| [backend/app/schemas/common.py](../backend/app/schemas/common.py) |
| [backend/app/schemas/market.py](../backend/app/schemas/market.py) |
| [backend/app/schemas/watchlist.py](../backend/app/schemas/watchlist.py) |
| [backend/app/services/.gitkeep](../backend/app/services/.gitkeep) |
| [backend/app/services/__init__.py](../backend/app/services/__init__.py) |
| [backend/app/services/account_service.py](../backend/app/services/account_service.py) |
| [backend/app/services/auth_service.py](../backend/app/services/auth_service.py) |
| [backend/app/services/market_service.py](../backend/app/services/market_service.py) |
| [backend/app/utils/.gitkeep](../backend/app/utils/.gitkeep) |
| [backend/pyproject.toml](../backend/pyproject.toml) |
| [backend/requirements.lock.txt](../backend/requirements.lock.txt) |
| [backend/requirements.txt](../backend/requirements.txt) |
| [backend/scripts/.gitkeep](../backend/scripts/.gitkeep) |
| [backend/scripts/__init__.py](../backend/scripts/__init__.py) |
| [backend/scripts/export_openapi.py](../backend/scripts/export_openapi.py) |
| [backend/scripts/sync_market_data.py](../backend/scripts/sync_market_data.py) |
| [docs/API_CONTRACT.md](../docs/API_CONTRACT.md) |
| [docs/contracts/examples.json](../docs/contracts/examples.json) |
| [docs/team/TV4_LB.md](../docs/team/TV4_LB.md) |

## TV5 — Tuệ — Trading engine, settlement, notifications

| File |
|---|
| [backend/app/api/v1/endpoints/notifications.py](../backend/app/api/v1/endpoints/notifications.py) |
| [backend/app/api/v1/endpoints/orders.py](../backend/app/api/v1/endpoints/orders.py) |
| [backend/app/api/v1/endpoints/transactions.py](../backend/app/api/v1/endpoints/transactions.py) |
| [backend/app/crud/notifications.py](../backend/app/crud/notifications.py) |
| [backend/app/crud/orders.py](../backend/app/crud/orders.py) |
| [backend/app/crud/transactions.py](../backend/app/crud/transactions.py) |
| [backend/app/models/notification.py](../backend/app/models/notification.py) |
| [backend/app/models/settlement.py](../backend/app/models/settlement.py) |
| [backend/app/models/stock_order.py](../backend/app/models/stock_order.py) |
| [backend/app/models/transaction.py](../backend/app/models/transaction.py) |
| [backend/app/schemas/notifications.py](../backend/app/schemas/notifications.py) |
| [backend/app/schemas/trading.py](../backend/app/schemas/trading.py) |
| [backend/app/services/matching_service.py](../backend/app/services/matching_service.py) |
| [backend/app/services/notification_service.py](../backend/app/services/notification_service.py) |
| [backend/app/services/order_service.py](../backend/app/services/order_service.py) |
| [backend/app/services/settlement_service.py](../backend/app/services/settlement_service.py) |
| [backend/scripts/settle_shares.py](../backend/scripts/settle_shares.py) |
| [docs/team/TV5_TUE.md](../docs/team/TV5_TUE.md) |

## TV6 — Châu — QA, integration evidence, report

| File |
|---|
| [backend/tests/conftest.py](../backend/tests/conftest.py) |
| [backend/tests/integration/.gitkeep](../backend/tests/integration/.gitkeep) |
| [backend/tests/integration/test_database_bootstrap.py](../backend/tests/integration/test_database_bootstrap.py) |
| [backend/tests/unit/.gitkeep](../backend/tests/unit/.gitkeep) |
| [backend/tests/unit/test_contract.py](../backend/tests/unit/test_contract.py) |
| [backend/tests/unit/test_http_contract.py](../backend/tests/unit/test_http_contract.py) |
| [docs/ACCEPTANCE_TESTS.md](../docs/ACCEPTANCE_TESTS.md) |
| [docs/WORK_BOARD.md](../docs/WORK_BOARD.md) |
| [docs/qa/PREPARATION_CHECK.md](../docs/qa/PREPARATION_CHECK.md) |
| [docs/qa/README.md](../docs/qa/README.md) |
| [docs/team/TV6_CHAU.md](../docs/team/TV6_CHAU.md) |
| [mobile/integration_test/README.md](../mobile/integration_test/README.md) |
| [mobile/test/unit/.gitkeep](../mobile/test/unit/.gitkeep) |
| [mobile/test/widget/.gitkeep](../mobile/test/widget/.gitkeep) |
| [scripts/check_preparation.py](../scripts/check_preparation.py) |
