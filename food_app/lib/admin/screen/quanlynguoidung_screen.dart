import 'package:flutter/material.dart';
import 'quanlychitietnguoidung.dart';
import '../../service/api_service.dart';

class QuanLyNguoiDungScreen extends StatefulWidget {
  const QuanLyNguoiDungScreen({super.key});

  @override
  State<QuanLyNguoiDungScreen> createState() => _QuanLyNguoiDungScreenState();
}

class _QuanLyNguoiDungScreenState extends State<QuanLyNguoiDungScreen> {
  final api = ApiService();
  List<dynamic> _tatCaNguoiDung = [];
  List<dynamic> _nguoiDungHienThi = [];
  String _tuKhoa = '';
  bool _dangTai = false;

  @override
  void initState() {
    super.initState();
    _taiNguoiDung();
  }

  Future<void> _taiNguoiDung() async {
    setState(() => _dangTai = true);
    try {
      final data = await api.getUsers();
      _tatCaNguoiDung = data;
      _locNguoiDung();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    } finally {
      setState(() => _dangTai = false);
    }
  }

  void _locNguoiDung() {
    setState(() {
      _nguoiDungHienThi = _tatCaNguoiDung.where((nd) {
        final tenDangNhap = nd['tenNguoiDung'] ?? '';
        final hoTen = nd['hoTen'] ?? '';
        final email = nd['email'] ?? '';
        return tenDangNhap.toLowerCase().contains(_tuKhoa.toLowerCase()) ||
            hoTen.toLowerCase().contains(_tuKhoa.toLowerCase()) ||
            email.toLowerCase().contains(_tuKhoa.toLowerCase());
      }).toList();
    });
  }

  Color _mauVaiTro(String vaiTro) {
    return vaiTro.toLowerCase() == 'admin' ? Colors.red : Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm theo tên đăng nhập, họ tên hoặc email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                _tuKhoa = value;
                _locNguoiDung();
              },
            ),
          ),

          // Danh sách người dùng
          Expanded(
            child: _dangTai
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _taiNguoiDung,
                    child: _nguoiDungHienThi.isEmpty
                        ? const Center(child: Text("Không có người dùng nào"))
                        : ListView.builder(
                            itemCount: _nguoiDungHienThi.length,
                            itemBuilder: (context, index) {
                              final nd = _nguoiDungHienThi[index];

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: ListTile(
                                  onTap: () async {
                                    final ketQua = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChiTietNguoiDungScreen(
                                          nguoiDung: nd,
                                          api: api,
                                        ),
                                      ),
                                    );
                                    if (ketQua == true) _taiNguoiDung();
                                  },
                                  leading: CircleAvatar(
                                    backgroundColor: _mauVaiTro(nd['vaiTro'] ?? 'User'),
                                    child: const Icon(Icons.person, color: Colors.white),
                                  ),
                                  title: Text(
                                    nd['tenNguoiDung'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(nd['hoTen'] ?? '-'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Vai trò
                                      Text(
                                        nd['vaiTro'] ?? 'User',
                                        style: TextStyle(
                                          color: _mauVaiTro(nd['vaiTro'] ?? 'User'),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Nút xóa
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text('Xác nhận'),
                                              content: Text(
                                                  'Bạn có chắc muốn xóa ${nd['tenNguoiDung']} không?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, false),
                                                  child: const Text('Hủy'),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context, true),
                                                  child: const Text('Xóa'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            final thanhCong = await api.deleteNguoiDung(nd['maTaiKhoan']);
                                            if (thanhCong) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Xóa thành công!')),
                                              );
                                              _taiNguoiDung();
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Xóa thất bại!')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
