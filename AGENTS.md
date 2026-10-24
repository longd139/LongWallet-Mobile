# Agent Rules - MobileApp

## Quy định Build APK (BẮT BUỘC)
- **TUYỆT ĐỐI CẤM** tự ý chạy lệnh build file APK (`flutter build apk`, `flutter build appbundle`, v.v.) sau mỗi task chỉnh sửa code hay commit thông thường.
- **CHỈ ĐƯỢC PHÉP** build file APK khi người dùng ra lệnh trực tiếp, rõ ràng (ví dụ: *"hãy build apk"*, *"xuất file apk giúp tôi"*, *"build apk đi"*).
- Đối với mọi task code/fix bug thông thường:
  - Chỉ chạy xác minh bằng lệnh `flutter test`.
  - Báo cáo số lượng test pass/fail đầy đủ.
  - Nhắc người dùng nhấn `r` trên terminal đang chạy `flutter run` để hot reload kiểm tra ngay lập tức.
