// ============================================================
//  FLUTTER
//  lib/screens/legal/legal_screen.dart
//  >> FILE MOI (Chinh sach & Dieu khoan)
// ============================================================

// lib/screens/legal/legal_screen.dart
//
// Chính sách & Điều khoản sử dụng của ứng dụng Mọng Fruits.
// Dùng chung 1 màn, chọn tab: Điều khoản / Chính sách bảo mật.

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LegalScreen extends StatelessWidget {
  final int initialTab;
  const LegalScreen({super.key, this.initialTab = 0});

  static const String contactPhone = '0338316893';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chính sách & Điều khoản'),
          bottom: const TabBar(
            labelColor: AppColors.coffee,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.coffee,
            tabs: [
              Tab(text: 'Điều khoản'),
              Tab(text: 'Bảo mật'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_TermsTab(), _PrivacyTab()],
        ),
      ),
    );
  }
}

class _TermsTab extends StatelessWidget {
  const _TermsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: const [
        _UpdatedAt(),
        _Section('1. Chấp nhận điều khoản', [
          'Khi tải, cài đặt hoặc sử dụng ứng dụng Mọng Fruits, bạn đồng ý với các điều khoản dưới đây. '
              'Nếu không đồng ý, vui lòng ngừng sử dụng ứng dụng.',
        ]),
        _Section('2. Tài khoản của bạn', [
          'Bạn đăng nhập bằng số điện thoại và mã OTP. Số điện thoại là định danh tài khoản và không thể thay đổi.',
          'Bạn chịu trách nhiệm bảo mật thiết bị và mã OTP của mình. Mọi đơn hàng phát sinh từ tài khoản được xem là do bạn thực hiện.',
          'Chúng tôi có quyền tạm khóa tài khoản có dấu hiệu gian lận, lạm dụng khuyến mãi hoặc gây ảnh hưởng tới hệ thống.',
        ]),
        _Section('3. Đặt hàng và thanh toán', [
          'Giá món hiển thị trên ứng dụng đã bao gồm thuế (nếu có). Đơn hàng chỉ được xác nhận sau khi thanh toán thành công hoặc được cửa hàng tiếp nhận.',
          'Ứng dụng hỗ trợ thanh toán khi nhận hàng và chuyển khoản qua mã QR.',
          'Giao dịch chuyển khoản sẽ không được tự động hoàn trả nếu bạn hủy đơn hàng. '
              'Trường hợp cần hỗ trợ hoàn tiền, vui lòng liên hệ cửa hàng.',
        ]),
        _Section('4. Hủy đơn và hoàn tiền', [
          'Bạn có thể hủy đơn trước khi cửa hàng bắt đầu pha chế. Sau thời điểm đó, đơn hàng không thể hủy.',
          'Với đơn đã thanh toán chuyển khoản, việc hoàn tiền được xử lý thủ công sau khi cửa hàng xác minh, '
              'thường trong vòng 3–5 ngày làm việc.',
        ]),
        _Section('5. Voucher và điểm thưởng', [
          'Mỗi voucher có điều kiện áp dụng riêng: giá trị giảm, đơn tối thiểu, hạn sử dụng và số lần sử dụng.',
          'Voucher dành cho khách hàng mới được cấp tự động sau lần đăng nhập đầu tiên, có hạn 7 ngày và mỗi mã chỉ dùng một lần.',
          'Voucher không có giá trị quy đổi thành tiền mặt và có thể bị thu hồi nếu phát hiện gian lận.',
          'Điểm thưởng được tích theo giá trị đơn hàng và có thể dùng để giảm trừ ở các đơn sau.',
        ]),
        _Section('6. Giao hàng', [
          'Thời gian giao hàng là ước tính và có thể thay đổi do thời tiết, giao thông hoặc lượng đơn.',
          'Vui lòng cung cấp địa chỉ và số điện thoại chính xác. Cửa hàng không chịu trách nhiệm với đơn giao sai do thông tin bạn nhập sai.',
        ]),
        _Section('7. Giới hạn trách nhiệm', [
          'Chúng tôi nỗ lực đảm bảo ứng dụng hoạt động ổn định, nhưng không cam kết ứng dụng luôn không bị gián đoạn hoặc lỗi.',
          'Chúng tôi không chịu trách nhiệm cho thiệt hại gián tiếp phát sinh từ việc sử dụng ứng dụng.',
        ]),
        _Section('8. Thay đổi điều khoản', [
          'Điều khoản có thể được cập nhật theo thời gian. Việc bạn tiếp tục sử dụng ứng dụng sau khi cập nhật đồng nghĩa với việc chấp nhận nội dung mới.',
        ]),
        _ContactBox(),
      ],
    );
  }
}

class _PrivacyTab extends StatelessWidget {
  const _PrivacyTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: const [
        _UpdatedAt(),
        _Section('1. Thông tin chúng tôi thu thập', [
          'Thông tin tài khoản: số điện thoại, tên hiển thị.',
          'Thông tin đơn hàng: món đã đặt, địa chỉ giao hàng, phương thức thanh toán, lịch sử giao dịch.',
          'Dữ liệu kỹ thuật cơ bản phục vụ vận hành và khắc phục sự cố.',
        ]),
        _Section('2. Mục đích sử dụng', [
          'Xác thực đăng nhập và bảo vệ tài khoản của bạn.',
          'Xử lý đơn hàng, giao hàng và thanh toán.',
          'Cấp và quản lý voucher, điểm thưởng.',
          'Cải thiện chất lượng dịch vụ và hỗ trợ khách hàng.',
        ]),
        _Section('3. Chia sẻ thông tin', [
          'Chúng tôi không bán thông tin cá nhân của bạn.',
          'Thông tin chỉ được chia sẻ với các bên phục vụ vận hành: đơn vị giao hàng, cổng thanh toán, dịch vụ xác thực số điện thoại.',
          'Chúng tôi có thể cung cấp thông tin khi có yêu cầu hợp pháp từ cơ quan nhà nước có thẩm quyền.',
        ]),
        _Section('4. Lưu trữ và bảo mật', [
          'Thông tin được lưu trên hệ thống máy chủ có kiểm soát truy cập. Mật khẩu, mã PIN được mã hóa một chiều.',
          'Dữ liệu đơn hàng được lưu để phục vụ đối soát, bảo hành quyền lợi khách hàng và tuân thủ quy định kế toán.',
          'Không có hệ thống nào an toàn tuyệt đối; chúng tôi nỗ lực áp dụng các biện pháp bảo vệ hợp lý.',
        ]),
        _Section('5. Quyền của bạn', [
          'Bạn có thể xem và cập nhật tên hiển thị trong mục Hồ sơ cá nhân.',
          'Bạn có quyền yêu cầu xóa tài khoản và dữ liệu cá nhân. Một số dữ liệu giao dịch có thể được giữ lại theo quy định pháp luật.',
          'Để thực hiện các quyền trên, vui lòng liên hệ cửa hàng theo thông tin bên dưới.',
        ]),
        _Section('6. Trẻ em', [
          'Ứng dụng không dành cho người dưới 13 tuổi. Chúng tôi không cố ý thu thập thông tin của trẻ em.',
        ]),
        _ContactBox(),
      ],
    );
  }
}

class _UpdatedAt extends StatelessWidget {
  const _UpdatedAt();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 18),
      child: Text('Cập nhật lần cuối: 07/2026',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> paragraphs;
  const _Section(this.title, this.paragraphs);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark)),
          const SizedBox(height: 8),
          ...paragraphs.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 7, right: 8),
                    child: CircleAvatar(
                        radius: 2.5, backgroundColor: AppColors.coffee),
                  ),
                  Expanded(
                    child: Text(p,
                        style: const TextStyle(
                            fontSize: 14,
                            height: 1.55,
                            color: AppColors.textDark)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBox extends StatelessWidget {
  const _ContactBox();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.coffee.withOpacity(0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Liên hệ',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.textDark)),
          SizedBox(height: 8),
          Text(
            'Mọi thắc mắc về điều khoản, quyền riêng tư hoặc đơn hàng, '
            'vui lòng liên hệ số điện thoại: ${LegalScreen.contactPhone}.',
            style: TextStyle(
                fontSize: 14, height: 1.5, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}