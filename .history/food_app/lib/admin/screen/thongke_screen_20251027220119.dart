import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../service/api_service.dart';

class ThongKeScreen extends StatefulWidget {
  const ThongKeScreen({super.key});

  @override
  State<ThongKeScreen> createState() => _ThongKeScreenState();
}

class _ThongKeScreenState extends State<ThongKeScreen> {
  final ApiService apiService = ApiService();

  bool _loading = true;
  int tongDonHang = 0;
  double doanhThu = 0.0;
  int tongNguoiDung = 0;
  int tongSanPham = 0;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    setState(() => _loading = true);
    try {
      // 1. Tổng đơn hàng và doanh thu
      final donHangs = await apiService.getOrders();
      tongDonHang = donHangs.length;
      // doanhThu = donHangs.fold(0.0, (sum, dh) => sum + (dh.tongTien));

      // 2. Tổng người dùng
      final nguoiDungs = await apiService.getUsers();
      tongNguoiDung = nguoiDungs.length;

      // 3. Tổng sản phẩm
      final sanPhams = await apiService.getProducts();
      tongSanPham = sanPhams.length;
    } catch (e) {
      debugPrint("Lỗi fetch dashboard: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      {
        'title': 'Tổng đơn hàng',
        'value': _loading ? '...' : '$tongDonHang',
        'icon': Icons.shopping_cart,
        'color': Colors.blue
      },
      {
        'title': 'Doanh thu',
        'value': _loading ? '...' : '${doanhThu.toStringAsFixed(0)}₫',
        'icon': Icons.monetization_on,
        'color': Colors.green
      },
      {
        'title': 'Người dùng',
        'value': _loading ? '...' : '$tongNguoiDung',
        'icon': Icons.people,
        'color': Colors.orange
      },
      {
        'title': 'Sản phẩm',
        'value': _loading ? '...' : '$tongSanPham',
        'icon': Icons.fastfood,
        'color': Colors.purple
      },
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Thống kê nhanh",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5),
              itemBuilder: (context, i) {
                final s = stats[i];
                final Color color = s['color'] as Color;
                final IconData icon = s['icon'] as IconData;
                final String value = s['value'].toString();
                final String title = s['title'].toString();

                return Container(
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.5 * 255).round()),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: color, width: 1),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, color: color, size: 32),
                      const SizedBox(height: 5),
                      Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 25),
            const Text(
              "Doanh thu 6 tháng gần đây",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // Biểu đồ tạm giữ cứng, có thể fetch sau từ backend
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          const months = ['T5', 'T6', 'T7', 'T8', 'T9', 'T10'];
                          return Text(months[value.toInt() % months.length]);
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 10, color: Colors.green)]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 12, color: Colors.green)]),
                    BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 8, color: Colors.green)]),
                    BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 14, color: Colors.green)]),
                    BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 11, color: Colors.green)]),
                    BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 16, color: Colors.green)]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
