# LongWallet - Mobile App (Flutter)

Ứng dụng quản lý tài chính cá nhân thông minh **LongWallet** xây dựng trên nền tảng **Flutter** kết nối **Supabase**, tích hợp lắng nghe thông báo biến động số dư ngân hàng Android (`NotificationListenerService`).

---

## ✨ Tính năng nổi bật
1. **Lắng nghe & Bắt biến động số dư tự động (Android)**:
   - Sử dụng `NotificationListenerService` chạy ngầm.
   - Bắt thông báo từ các ngân hàng & ví điện tử: Vietcombank, MB Bank, Techcombank, BIDV, VietinBank, MoMo, ZaloPay...
   - Bộ phân tích **Regex Engine** bóc tách số tiền (+/-), số tài khoản, nội dung chuyển khoản.
   - Cơ chế băm **SHA-256 (`raw_hash`)** chống trùng lặp giao dịch.
   - Màn hình duyệt nhanh giao dịch tự động phát hiện (`PENDING` -> `CONFIRMED`).

2. **Quản lý đa ví (Wallets)**:
   - Ví tiền mặt, tài khoản ngân hàng, ví điện tử.
   - Cập nhật số dư tự động theo thời gian thực qua Supabase Database Triggers.

3. **Ghi chép & Thống kê**:
   - Thêm giao dịch thu / chi thủ công nhanh chóng.
   - Báo cáo tài chính, tổng thu, tổng chi và dòng tiền ròng.

4. **Bảo mật**:
   - Xác thực qua Supabase Auth.
   - Row-Level Security (RLS) bảo vệ dữ liệu cá nhân theo người dùng.
   - Hỗ trợ khóa ứng dụng bằng sinh trắc học (Vân tay / FaceID).

---

## 📂 Cấu trúc dự án
```
MobileApp/
├── android/
│   ├── app/src/main/
│   │   ├── AndroidManifest.xml                  # Cấp quyền BIND_NOTIFICATION_LISTENER_SERVICE
│   │   └── kotlin/com/longwallet/
│   │       ├── MainActivity.kt                  # MethodChannel & EventChannel bridge
│   │       └── NotificationListener.kt          # Android Background Service bắt thông báo
├── lib/
│   ├── core/
│   │   ├── constants/app_constants.dart         # Cấu hình Supabase & Bank mapping
│   │   ├── services/
│   │   │   ├── bank_parser_service.dart         # Regex bóc tách số tiền & từ khóa
│   │   │   ├── notification_service.dart        # Kênh giao tiếp Flutter <-> Android Native
│   │   │   └── supabase_service.dart            # CRUD dữ liệu với Supabase
│   │   └── theme/app_theme.dart                 # Giao diện Dark Material 3 cao cấp
│   ├── models/                                  # Data models (Wallet, Transaction, Category, Budget)
│   ├── providers/                               # Quản lý trạng thái (Auth, Wallet, Transaction)
│   ├── screens/
│   │   ├── auth/login_screen.dart               # Đăng nhập & Đăng ký
│   │   ├── home/home_screen.dart                # Dashboard tổng quan
│   │   ├── wallets/wallets_screen.dart          # Danh sách & Thêm ví
│   │   ├── transactions/
│   │   │   ├── add_transaction_screen.dart      # Thêm giao dịch thủ công
│   │   │   └── pending_transactions_screen.dart # Duyệt biến động số dư ngân hàng
│   │   └── stats/stats_screen.dart              # Báo cáo thống kê thu chi
│   └── main.dart                                # Điểm khởi chạy ứng dụng
└── pubspec.yaml                                 # Cấu hình thư viện dependencies
```

---

## 🚀 Hướng dẫn chạy ứng dụng
1. Cài đặt dependencies:
   ```bash
   flutter pub get
   ```
2. Chạy trên thiết bị Android:
   ```bash
   flutter run
   ```
3. Khi khởi động ứng dụng lần đầu, vui lòng bấm **"Cài đặt"** trên thông báo popup để cấp quyền **"Truy cập thông báo" (Notification Access)** cho LongWallet trong cài đặt Android.
