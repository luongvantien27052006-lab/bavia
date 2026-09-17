// lib/core/config/vn_banks.dart
// Danh sách ngân hàng VN + mã BIN (napas) để tạo VietQR (img.vietqr.io).

class VnBank {
  final String code; // BIN napas (dùng cho VietQR)
  final String name;
  const VnBank(this.code, this.name);
}

class VnBanks {
  static const List<VnBank> list = [
    VnBank('970436', 'Vietcombank (VCB)'),
    VnBank('970422', 'MB Bank (MB)'),
    VnBank('970407', 'Techcombank (TCB)'),
    VnBank('970415', 'VietinBank (CTG)'),
    VnBank('970418', 'BIDV'),
    VnBank('970405', 'Agribank'),
    VnBank('970432', 'VPBank'),
    VnBank('970416', 'ACB'),
    VnBank('970423', 'TPBank'),
    VnBank('970403', 'Sacombank (STB)'),
    VnBank('970441', 'VIB'),
    VnBank('970426', 'MSB'),
    VnBank('970443', 'SHB'),
    VnBank('970437', 'HDBank'),
    VnBank('970448', 'OCB'),
    VnBank('970429', 'SCB'),
    VnBank('970431', 'Eximbank (EIB)'),
    VnBank('970449', 'LienVietPostBank (LPB)'),
    VnBank('970428', 'Nam A Bank'),
    VnBank('970425', 'ABBANK'),
    VnBank('970419', 'NCB'),
    VnBank('970409', 'BacABank'),
    VnBank('970412', 'PVcomBank'),
    VnBank('970414', 'Ocean Bank'),
    VnBank('970438', 'BaoVietBank'),
    VnBank('970440', 'SeABank'),
    VnBank('970446', 'Co-opBank'),
    VnBank('970454', 'VietCapitalBank (BVBank)'),
    VnBank('970430', 'PGBank'),
    VnBank('546034', 'Cake by VPBank'),
    VnBank('963388', 'Timo'),
  ];
}
