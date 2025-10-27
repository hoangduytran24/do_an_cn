import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../service/api_service.dart';

// Import các màn hình quản lý
import 'thongke_screen.dart';
import 'quanlysanpham.dart';
import 'quanlydanhmuc_screen.dart';
import 'quanlydonhang.dart';
import 'quanlynguoidung_screen.dart';
import 'quanlyphieugiamgia.dart';
import 'caidat.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  final ApiService apiService = ApiService();
  Map<String, dynamic>? _userInfo; // ✅ thêm biến lưu thông tin người dùng

  // Danh sách màn hình quản lý
  late final List<Map<String, dynamic>> _screens = [
    {
      'title': 'Trang chủ',
      'screen': const ThongKeScreen(),
      'icon': Iconsax.home
    },
    {
      'title': 'Quản lý sản phẩm',
      'screen': const QuanLySanPhamScreen(),
      'icon': Iconsax.box
    },
    {
      'title': 'Quản lý danh mục',
      'screen': const QuanLyDanhMucScreen(),
      'icon': Iconsax.category
    },
    {
      'title': 'Quản lý đơn hàng',
      'screen': const QuanLyDonHangScreen(),
      'icon': Iconsax.shopping_bag
    },
    {
      'title': 'Quản lý người dùng',
      'screen': const QuanLyNguoiDungScreen(),
      'icon': Iconsax.profile_2user
    },
    {
      'title': 'Quản lý mã giảm giá',
      'screen': const QuanLyPhieuGiamGiaScreen(),
      'icon': Iconsax.discount_shape
    },
    {
      'title': 'Quản lý khuyến mãi',
      'icon': Iconsax.magicpen
    },
    {
      'title': 'Cài đặt',
      'screen': const CaiDatScreen(),
      'icon': Iconsax.setting
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = await apiService.getUserInfo();
      setState(() {
        _userInfo = user;
      });
    } catch (e) {
      print('Lỗi load thông tin người dùng: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _screens[_selectedIndex]['screen'],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        _screens[_selectedIndex]['title'],
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      backgroundColor: const Color(0xFF2E7D32),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Iconsax.notification),
          onPressed: () {},
        ),

      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          // Header Drawer
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: const Icon(
                    Iconsax.profile_circle,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _userInfo?['tenTaiKhoan'] ?? 'Quản trị viên',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userInfo?['email'] ?? 'admin@example.com',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Danh sách menu
          ...List.generate(
            _screens.length,
            (index) => ListTile(
              leading: Icon(
                _screens[index]['icon'],
                color: _selectedIndex == index
                    ? const Color(0xFF2E7D32)
                    : Colors.grey.shade700,
              ),
              title: Text(
                _screens[index]['title'],
                style: TextStyle(
                  fontWeight: _selectedIndex == index
                      ? FontWeight.w600
                      : FontWeight.normal,
                  color: _selectedIndex == index
                      ? const Color(0xFF2E7D32)
                      : Colors.grey.shade700,
                ),
              ),
              selected: _selectedIndex == index,
              selectedTileColor: const Color(0xFF2E7D32).withOpacity(0.1),
              onTap: () {
                setState(() => _selectedIndex = index);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CaiDatScreen();
  }
}

class ThongKeManagementScreen extends StatelessWidget {
  const ThongKeManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ThongKeScreen();
  }
}

class DanhMucManagementScreen extends StatelessWidget {
  const DanhMucManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuanLyDanhMucScreen();
  }
}

class DonHangManagementScreen extends StatelessWidget {
  const DonHangManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuanLyDonHangScreen();
  }
}
class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuanLySanPhamScreen();
  }
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuanLyNguoiDungScreen();
  }
}

class CouponManagementScreen extends StatelessWidget {
  const CouponManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const QuanLyPhieuGiamGiaScreen();
  }
}