import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../service/api_service.dart';
import '../../models/coupon.dart';

class QuanLyPhieuGiamGiaScreen extends StatefulWidget {
  const QuanLyPhieuGiamGiaScreen({super.key});

  @override
  State<QuanLyPhieuGiamGiaScreen> createState() => _QuanLyPhieuGiamGiaScreenState();
}

class _QuanLyPhieuGiamGiaScreenState extends State<QuanLyPhieuGiamGiaScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<PhieuGiamGia> _coupons = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final Color _primaryColor = Color(0xFF10B981);
  final Color _backgroundColor = Color(0xFFF8FAFD);
  final Color _cardColor = Colors.white;
  final Color _textColor = Color(0xFF1E293B);
  final Color _secondaryTextColor = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupons() async {
    try {
      setState(() => _isLoading = true);
      final apiService = Provider.of<ApiService>(context, listen: false);
      _coupons = await apiService.getAllCoupons();
    } catch (e) {
      _showSnackbar('Lỗi tải dữ liệu: $e', false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterCoupons() {
    setState(() {
      _searchQuery = _searchController.text.trim();
    });
  }

  List<PhieuGiamGia> get _filteredCoupons {
    if (_searchQuery.isEmpty) return _coupons;
    return _coupons.where((coupon) =>
      coupon.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      coupon.moTa.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _deleteCoupon(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Xác nhận xóa', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa phiếu giảm giá này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: _secondaryTextColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final success = await apiService.deleteCoupon(id);
      
      if (success) {
        _showSnackbar('Xóa thành công', true);
        _loadCoupons();
      } else {
        _showSnackbar('Xóa thất bại', false);
      }
    } catch (e) {
      _showSnackbar('Lỗi: $e', false);
    }
  }

  void _showAddEditDialog({PhieuGiamGia? coupon}) {
    final codeCtrl = TextEditingController(text: coupon?.code ?? '');
    final valueCtrl = TextEditingController(text: coupon?.giaTri.toString() ?? '');
    final descCtrl = TextEditingController(text: coupon?.moTa ?? '');

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                coupon == null ? 'Thêm mã giảm giá' : 'Sửa mã giảm giá',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textColor),
              ),
              SizedBox(height: 24),
              _buildTextField(
                controller: codeCtrl,
                label: 'Mã giảm giá',
                icon: Icons.local_offer_outlined,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: valueCtrl,
                label: 'Giá trị',
                icon: Icons.attach_money_outlined,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16),
              _buildTextField(
                controller: descCtrl,
                label: 'Mô tả',
                icon: Icons.description_outlined,
                maxLines: 2,
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Hủy', style: TextStyle(color: _secondaryTextColor)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (codeCtrl.text.isEmpty || valueCtrl.text.isEmpty) {
                          _showSnackbar('Vui lòng nhập đầy đủ thông tin', false);
                          return;
                        }

                        final giaTri = double.tryParse(valueCtrl.text);
                        if (giaTri == null) {
                          _showSnackbar('Giá trị không hợp lệ', false);
                          return;
                        }

                        final newCoupon = PhieuGiamGia(
                          idPhieuGiamGia: coupon?.idPhieuGiamGia ?? '',
                          code: codeCtrl.text.trim(),
                          giaTri: giaTri,
                          moTa: descCtrl.text.trim(),
                        );

                        try {
                          final apiService = Provider.of<ApiService>(context, listen: false);
                          String result;
                          
                          if (coupon == null) {
                            result = await apiService.createCoupon(newCoupon);
                          } else {
                            result = await apiService.updateCoupon(coupon.idPhieuGiamGia, newCoupon);
                          }

                          _showSnackbar(result, true);
                          _loadCoupons();
                          Navigator.pop(context);
                        } catch (e) {
                          _showSnackbar('Lỗi: $e', false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Lưu', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _secondaryTextColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _primaryColor),
        ),
      ),
    );
  }

  void _showSnackbar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? _primaryColor : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _getVoucherColor(double giaTri) {
    if (giaTri <= 100) return Color(0xFF667EEA);
    if (giaTri >= 100000) return Color(0xFFFF6B6B);
    if (giaTri >= 50000) return Color(0xFFFFA726);
    return _primaryColor;
  }

  String _getDiscountText(PhieuGiamGia voucher) {
    return voucher.giaTri <= 100 ? '${voucher.giaTri}%' : '${voucher.giaTri.toInt()}₫';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      // Nút thêm ở góc phải dưới
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: _primaryColor,
        elevation: 4,
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: Column(
        children: [
          // Header đã bỏ title
          Container(
            padding: EdgeInsets.fromLTRB(24, 56, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Đã bỏ phần Row chứa title
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _filterCoupons(),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm mã giảm giá...',
                      prefixIcon: Icon(Icons.search, color: _secondaryTextColor),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: _primaryColor),
                        SizedBox(height: 16),
                        Text(
                          'Đang tải dữ liệu...',
                          style: TextStyle(color: _secondaryTextColor),
                        ),
                      ],
                    ),
                  )
                : _filteredCoupons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_giftcard, size: 80, color: Colors.grey.shade300),
                            SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty 
                                  ? 'Chưa có mã giảm giá'
                                  : 'Không tìm thấy kết quả',
                              style: TextStyle(fontSize: 16, color: _secondaryTextColor),
                            ),
                            if (_searchQuery.isNotEmpty) ...[
                              SizedBox(height: 8),
                              Text(
                                'Thử tìm kiếm với từ khóa khác',
                                style: TextStyle(color: _secondaryTextColor),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(24),
                        itemCount: _filteredCoupons.length,
                        itemBuilder: (context, index) {
                          final voucher = _filteredCoupons[index];
                          return _buildVoucherCard(voucher);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherCard(PhieuGiamGia voucher) {
    final color = _getVoucherColor(voucher.giaTri);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Header với hiệu ứng gradient
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  // Badge giá trị
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getDiscountText(voucher),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          voucher.code,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (voucher.moTa.isNotEmpty) ...[
                          SizedBox(height: 6),
                          Text(
                            voucher.moTa,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(16),
              color: _cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    voucher.code,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      _buildActionButton(
                        icon: Icons.edit_outlined,
                        color: Colors.blue,
                        onPressed: () => _showAddEditDialog(coupon: voucher),
                      ),
                      SizedBox(width: 8),
                      _buildActionButton(
                        icon: Icons.delete_outlined,
                        color: Colors.red,
                        onPressed: () => _deleteCoupon(voucher.idPhieuGiamGia),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        padding: EdgeInsets.all(8),
        constraints: BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}