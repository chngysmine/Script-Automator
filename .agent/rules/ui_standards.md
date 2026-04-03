# Script Automator UI/UX Standards (2026 Edition)

## 1. Liquid Glass 2.0 (Component: `LiquidGlass`)
Mọi hiệu ứng kính mờ trong hệ thống (overlay, widget frame, modal...) phải tuân thủ chuẩn Kính Động (Liquid Glass 2.0):
- **BackdropFilter:** `sigmaX: 25`, `sigmaY: 25` (Không dùng blur thấp hơn 20 vì sẽ bị đục).
- **Background Color:** `Colors.white.withValues(alpha: 0.1)` cho Light Mode, hoặc gradient cực nhạt.
- **Specular Highlight (Viền Phản Quang):** BẮT BUỘC có viền `Border.all(color: Colors.white.withValues(alpha: 0.4), width: 0.5)` để tách nền rỗng.
- **Soft Shadow:** Đổ bóng lan tỏa `blurRadius: 20`, `offset: Offset(0, 8)` với opacity 0.05.

## 2. Dynamic Mesh Gradient (Component: `MeshGradientBackground`)
Không sử dụng màu nền đơn sắc (Flat Colors) hoặc tĩnh (Static) cho các khung cảnh chính (Dashboard, Search, Gallery, Profile).
- Dùng `MeshGradientBackground` với Shader phân mảnh mờ (`MaskFilter.blur` 120+).
- Mesh phải có ít nhất 3 nguồn sáng màu (Orbs) hoà quyện vào nhau và di chuyển bằng AnimationController vô hạn.

## 3. Bento Grid 2.0 Layout
Đối với các danh sách chứa item (Scripts, Plugins, Logs):
- KHÔNG DÙNG Dạng List (ListTile) màn hình đơn điệu.
- PHẢI dùng Bento Grid với các Tile kích thước ngẫu nhiên nhưng nằm trong lưới (Large, Wide, Small).
- **Image Placeholder:** Mọi Card (như `LiquidBentoCard`) phải dành ít nhất 40% diện tích (AspectRatio) nửa trên để làm không gian ảnh cover (sau này load qua mạng) hoặc gradient có Logo ấn tượng. Nửa dưới dành cho metadata chữ.
- **Spring Physics:** Mọi Card phải có tương tác chạm vật lý dạng lò xo (AnimatedScale kết hợp `Curves.elasticOut` hoặc `easeOutBack`).

## 4. AI-First & Predictive Search
- Các luồng tìm kiếm không bao giờ là trang trắng thụ động.
- Thanh tìm kiếm ưu tiên nằm trên cùng (Omnibar) và có tích hợp icon phát sáng (Glow AI).
- Khi người dùng Focus vào trường tìm kiếm, lập tức hiện Overlay màn hình mờ chứa các danh sách dự đoán: Trending, Recent, Generate with AI thay vì giấu chúng vào menu tĩnh.

## 5. Gamification System 
- Tất cả UI thống kê người dùng (Ví dụ: Trang Profile) phải được Game hóa.
- Thành tích phải lưu dưới dạng Badges thủy tinh.
- Có thanh XP cong đẹp mắt thể hiện tiến độ.
- Có quà tặng ngẫu nhiên hằng ngày (Gacha Logic).
