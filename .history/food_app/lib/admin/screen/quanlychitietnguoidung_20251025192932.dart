import 'package:flutter/material.dart';
import '../../service/api_service.dart';
class ChiTietNguoiDungScreen extends StatefulWidget {
  final Map<String, dynamic> nguoiDung;
  final ApiService api;

  const ChiTietNguoiDungScreen({super.key, required this.nguoiDung, required this.api});

  @override
  State<ChiTietNguoiDungScreen> createState() => _ChiTietNguoiDungScreenState();
}

class _ChiTietNguoiDungScreenState extends State<ChiTietNguoiDungScreen> {
  late TextEditingController _tenNguoiDungCtrl;
  late TextEditingController _hoTenCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _sdtCtrl;
  late TextEditingController _diaChiCtrl;

  String _vaiTro = 'User';
  bool _dangLuu = false;

  final List<String> _vaiTroHople = ['User', 'Admin'];

  @override
  void initState() {
    super.initState();
    final nd = widget.nguoiDung;
    _tenNguoiDungCtrl = TextEditingController(text: nd['tenNguoiDung'] ?? '');
    _hoTenCtrl = TextEditingController(text: nd['hoTen'] ?? '');
    _emailCtrl = TextEditingController(text: nd['email'] ?? '');
    _sdtCtrl = TextEditingController(text: nd['sdt'] ?? '');
    _diaChiCtrl = TextEditingController(text: nd['diaChi'] ?? '');

    // ⚡ Fix dropdown value
    final vaiTroBanDau = nd['vaiTro']?.toString() ?? '';
    _vaiTro = _vaiTroHople.firstWhere(
      (v) => v.toLowerCase() == vaiTroBanDau.toLowerCase(),
      orElse: () => 'User',
    );
  }

  Future<void> _capNhatNguoiDung() async {
    setState(() => _dangLuu = true);

    final data = {
      "TenNguoiDung": _tenNguoiDungCtrl.text.trim(),
      "HoTen": _hoTenCtrl.text.trim(),
      "Email": _emailCtrl.text.trim(),
      "Sdt": _sdtCtrl.text.trim(),
      "DiaChi": _diaChiCtrl.text.trim(),
      "VaiTro": _vaiTro,
    };

    try {
      final thanhCong =
          await widget.api.updateNguoiDung(widget.nguoiDung['maTaiKhoan'], data);
      if (thanhCong) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thành công!')),
        );
        Navigator.pop(context, true); // Báo trang trước
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thất bại!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() => _dangLuu = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Người dùng: ${widget.nguoiDung['tenNguoiDung'] ?? ''}'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _tenNguoiDungCtrl,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hoTenCtrl,
              decoration: const InputDecoration(
                labelText: 'Họ và tên',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sdtCtrl,
              decoration: const InputDecoration(
                labelText: 'Số điện thoại',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _diaChiCtrl,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Vai trò: ', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _vaiTro,
                  items: _vaiTroHople.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _vaiTro = value);
                  },
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _dangLuu ? null : _capNhatNguoiDung,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: _dangLuu
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Lưu thay đổi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
