// service/api_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Product.dart';
import '../models/user.dart';
import '../models/cart.dart';
import '../models/Category.dart';
import '../models/order.dart';
import '../models/Rating.dart';
import '../models/coupon.dart';
import '../models/pay.dart';

class ApiService {
  final String baseUrl = "https://10.0.2.2:7240/api";

  // Lấy token từ SharedPreferences
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Headers với Authorization
  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTHENTICATION ====================
  
  // Đăng nhập bằng email
  Future<User?> login(String email, String matKhau) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/User/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'matKhau': matKhau,
        }),
      ).timeout(const Duration(seconds: 30));

      print('Login API Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = User.fromJson(data['user']);
        
        // Lưu thông tin user vào SharedPreferences
        await _saveUserInfo(user);
        return user;
      } else {
        throw Exception('Đăng nhập thất bại: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Lỗi đăng nhập: $e');
    }
  }

  // Đăng ký
  Future<bool> register(User user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/User/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Lỗi đăng ký: $e');
    }
  }

  // Lưu thông tin user
  Future<void> _saveUserInfo(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('maTaiKhoan', user.maTaiKhoan);
    await prefs.setString('tenNguoiDung', user.tenNguoiDung);
    await prefs.setString('email', user.email);
    await prefs.setString('hoTen', user.hoTen);
    await prefs.setString('sdt', user.sdt);
    await prefs.setString('diaChi', user.diaChi);
    await prefs.setString('vaiTro', user.vaiTro);
    await prefs.setBool('isLoggedIn', true);
  }

  // Đăng xuất
  Future<bool> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      return true;
    } catch (e) {
      print('Error during logout: $e');
      return false;
    }
  }

  // Kiểm tra đăng nhập
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Lấy thông tin user từ SharedPreferences
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    if (!isLoggedIn) return null;

    return User(
      maTaiKhoan: prefs.getString('maTaiKhoan') ?? '',
      tenNguoiDung: prefs.getString('tenNguoiDung') ?? '',
      matKhau: '', // Không lưu mật khẩu
      email: prefs.getString('email') ?? '',
      hoTen: prefs.getString('hoTen') ?? '',
      sdt: prefs.getString('sdt') ?? '',
      diaChi: prefs.getString('diaChi') ?? '',
      vaiTro: prefs.getString('vaiTro') ?? '',
    );
  }

  // ==================== USER INFO ====================

  // Lấy thông tin chi tiết người dùng từ API
  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final headers = await getHeaders();
      final user = await getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      final response = await http.get(
        Uri.parse('$baseUrl/User/${user.maTaiKhoan}'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('User Info API Response: ${response.statusCode}');
      print('User Info API Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('User info data: $data');
        
        return {
          'maTaiKhoan': data['maTaiKhoan'] ?? '',
          'tenTaiKhoan': data['tenNguoiDung'] ?? data['hoTen'] ?? 'Người dùng',
          'email': data['email'] ?? '',
          'hoTen': data['hoTen'] ?? '',
          'sdt': data['sdt'] ?? '',
          'diaChi': data['diaChi'] ?? '',
          'vaiTro': data['vaiTro'] ?? 'user',
        };
      } else {
        final prefs = await SharedPreferences.getInstance();
        return {
          'maTaiKhoan': prefs.getString('maTaiKhoan') ?? '',
          'tenTaiKhoan': prefs.getString('tenNguoiDung') ?? prefs.getString('hoTen') ?? 'Người dùng',
          'email': prefs.getString('email') ?? '',
          'hoTen': prefs.getString('hoTen') ?? '',
          'sdt': prefs.getString('sdt') ?? '',
          'diaChi': prefs.getString('diaChi') ?? '',
          'vaiTro': prefs.getString('vaiTro') ?? 'user',
        };
      }
    } catch (e) {
      print('Error getting user info: $e');
      final prefs = await SharedPreferences.getInstance();
      return {
        'maTaiKhoan': prefs.getString('maTaiKhoan') ?? '',
        'tenTaiKhoan': prefs.getString('tenNguoiDung') ?? prefs.getString('hoTen') ?? 'Người dùng',
        'email': prefs.getString('email') ?? '',
        'hoTen': prefs.getString('hoTen') ?? '',
        'sdt': prefs.getString('sdt') ?? '',
        'diaChi': prefs.getString('diaChi') ?? '',
        'vaiTro': prefs.getString('vaiTro') ?? 'user',
      };
    }
  }

  // Cập nhật thông tin người dùng
  Future<bool> updateUserInfo(Map<String, dynamic> userData) async {
    try {
      final headers = await getHeaders();
      final user = await getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      final response = await http.put(
        Uri.parse('$baseUrl/User/${user.maTaiKhoan}'),
        headers: headers,
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        if (userData.containsKey('tenNguoiDung')) {
          await prefs.setString('tenNguoiDung', userData['tenNguoiDung']);
        }
        if (userData.containsKey('hoTen')) {
          await prefs.setString('hoTen', userData['hoTen']);
        }
        if (userData.containsKey('sdt')) {
          await prefs.setString('sdt', userData['sdt']);
        }
        if (userData.containsKey('diaChi')) {
          await prefs.setString('diaChi', userData['diaChi']);
        }
        if (userData.containsKey('email')) {
          await prefs.setString('email', userData['email']);
        }
        
        return true;
      } else {
        throw Exception('Failed to update user info: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user info: $e');
    }
  }


Future<List<Map<String, dynamic>>> getUsers() async {
  try {
    final res = await http.get(
      Uri.parse('$baseUrl/User'),
      headers: await getHeaders(),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    
    // Parse thành List<Map<String, dynamic>>
    final List<dynamic> data = jsonDecode(res.body);
    return data.map((e) => e as Map<String, dynamic>).toList();
  } catch (e) {
    throw Exception('Error: $e');
  }
}
  Future<bool> updateNguoiDung(String maTaiKhoan, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('$baseUrl/User/$maTaiKhoan'),
     body: jsonEncode(data));
    return res.statusCode == 200;
  }
  Future<bool> deleteNguoiDung(String maTaiKhoan) async {
    final res = await http.delete(Uri.parse('$baseUrl/User/$maTaiKhoan'));
    return res.statusCode == 200;
  }
  // ==================== PRODUCTS ====================

Future<List<Product>> getProducts() async {
  try {
    final res = await http.get(
      Uri.parse('$baseUrl/Product'),
      headers: await getHeaders(),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
    return (jsonDecode(res.body) as List)
        .map((e) => Product.fromJson(e))
        .toList();
  } catch (e) {
    throw Exception('Error: $e');
  }
}

  Future<Product?> getProductById(String id) async {
  try {
    final res = await http.get(
      Uri.parse('$baseUrl/Product/$id'),
      headers: await getHeaders(),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      print('Failed to load product $id: ${res.statusCode}');
      return null;
    }

    final data = jsonDecode(res.body);
    if (data is List && data.isNotEmpty) return Product.fromJson(data.first);
    if (data is Map<String, dynamic>) return Product.fromJson(data);

    print('Unexpected format for $id: ${data.runtimeType}');
    return null;
  } catch (e) {
    print('Error fetching $id: $e');
    return null;
  }
}

  //search products by name
  Future<List<Product>> searchProducts(String name) async {
    final response = await http.get(Uri.parse('$baseUrl/Product/Search?name=$name'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Không tìm thấy sản phẩm');
    }
  }

// Trong ApiService class
Future<bool> addProduct(Product product, File? imageFile) async {
  try {
    var request = http.MultipartRequest(
      'POST', 
      Uri.parse('$baseUrl/Product')
    );
    
    // Thêm các trường dữ liệu
    request.fields['TenSanPham'] = product.tenSanPham;
    request.fields['MoTa'] = product.moTa;
    request.fields['GiaBan'] = product.giaBan.toString();
    request.fields['SoLuongTon'] = product.soLuongTon.toString();
    request.fields['XuatXu'] = product.xuatXu;
    request.fields['DonViTinh'] = product.donViTinh;
    request.fields['MaDanhMuc'] = product.maDanhMuc;
    
    // Thêm file ảnh nếu có
    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'Anh', 
        imageFile.path
      ));
    }
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(responseData);
      return jsonResponse['message'] == 'Thêm sản phẩm thành công';
    }
    return false;
  } catch (e) {
    throw Exception('Lỗi thêm sản phẩm: $e');
  }
}

Future<bool> updateProduct(String id, Product product, File? imageFile) async {
  try {
    var request = http.MultipartRequest(
      'PUT', 
      Uri.parse('$baseUrl/Product/$id')
    );
    
    // Thêm các trường dữ liệu
    request.fields['TenSanPham'] = product.tenSanPham;
    request.fields['MoTa'] = product.moTa;
    request.fields['GiaBan'] = product.giaBan.toString();
    request.fields['SoLuongTon'] = product.soLuongTon.toString();
    request.fields['XuatXu'] = product.xuatXu;
    request.fields['DonViTinh'] = product.donViTinh;
    request.fields['MaDanhMuc'] = product.maDanhMuc;
    
    // Thêm file ảnh nếu có
    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'Anh', 
        imageFile.path
      ));
    }
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(responseData);
      return jsonResponse['message'] == 'Cập nhật sản phẩm thành công';
    }
    return false;
  } catch (e) {
    throw Exception('Lỗi cập nhật sản phẩm: $e');
  }
}

Future<bool> deleteProduct(String id) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/Product/$id'),
    );
    
    if (response.statusCode == 200) {
      return response.body.contains('Xóa sản phẩm thành công');
    }
    return false;
  } catch (e) {
    throw Exception('Lỗi xóa sản phẩm: $e');
  }
}

  // ==================== FAVORITES ====================
  
  Future<bool> addToFavorites(String productId) async {
    try {
      final headers = await getHeaders();
      final user = await getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      final response = await http.post(
        Uri.parse('$baseUrl/Favorite'),
        headers: headers,
        body: jsonEncode({
          'maTaiKhoan': user.maTaiKhoan,
          'maSanPham': productId,
        }),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      throw Exception('Error adding to favorites: $e');
    }
  }

  Future<List<Product>> getFavorites() async {
    try {
      final headers = await getHeaders();
      final user = await getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      print('Fetching favorites for user: ${user.maTaiKhoan}');
      final response = await http.get(
        Uri.parse('$baseUrl/Favorite/User/${user.maTaiKhoan}'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('Favorites API Response: ${response.statusCode}');
      print('Favorites API Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Favorites data: $data');
        
        final List<String> productIds = [];
        for (var item in data) {
          if (item is Map<String, dynamic> && item.containsKey('maSanPham')) {
            productIds.add(item['maSanPham'].toString());
          }
        }
        
        print('Product IDs from favorites: $productIds');
        
        final List<Product> products = [];
        for (var productId in productIds) {
          try {
            final product = await getProductById(productId);
            if (product != null) {
              print('Loaded product: ${product.tenSanPham}');
              products.add(product);
            }
          } catch (e) {
            print('Error loading product $productId: $e');
          }
        }
        
        print('Converted ${products.length} products');
        return products;
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting favorites: $e');
      throw Exception('Error getting favorites: $e');
    }
  }

  // Lấy số lượng sản phẩm yêu thích bằng cách đếm từ danh sách
  Future<int> getFavoriteCount() async {
    try {
      final favorites = await getFavorites();
      return favorites.length;
    } catch (e) {
      print('Error getting favorite count: $e');
      return 0;
    }
  }

  Future<bool> removeFromFavoritesByProductId(String productId) async {
    try {
      final headers = await getHeaders();
      final user = await getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      final response = await http.delete(
        Uri.parse('$baseUrl/Favorite/Product/${user.maTaiKhoan}/$productId'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error removing from favorites: $e');
    }
  }

  // ==================== CART ====================
  
  Future<CartResponse> getCart() async {
    try {
      final headers = await getHeaders();
      final user = await getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      print('Fetching cart for user: ${user.maTaiKhoan}');
      final response = await http.get(
        Uri.parse('$baseUrl/Carts/user/${user.maTaiKhoan}'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('Cart API Response: ${response.statusCode}');
      print('Cart API Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        print('Cart data: $data');
        
        final cartResponse = CartResponse.fromJson(data);
        print('Converted ${cartResponse.sanPham.length} cart items');
        return cartResponse;
      } else {
        throw Exception('Failed to load cart: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error getting cart: $e');
      throw Exception('Error getting cart: $e');
    }
  }

  Future<bool> addToCart(String productId, int quantity) async {
    try {
      final headers = await getHeaders();
      final user = await getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      final response = await http.post(
        Uri.parse('$baseUrl/Carts/add'),
        headers: headers,
        body: jsonEncode({
          'maTaiKhoan': user.maTaiKhoan,
          'maSanPham': productId,
          'soLuong': quantity,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to add to cart');
      }
    } catch (e) {
      throw Exception('Error adding to cart: $e');
    }
  }

  Future<bool> removeFromCart(String productId) async {
    try {
      final headers = await getHeaders();
      final user = await getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      final response = await http.delete(
        Uri.parse('$baseUrl/Carts/remove/${user.maTaiKhoan}/$productId'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to remove from cart');
      }
    } catch (e) {
      throw Exception('Error removing from cart: $e');
    }
  }

  Future<bool> updateCartItem(String productId, int quantity) async {
    try {
      final headers = await getHeaders();
      final user = await getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      final response = await http.put(
        Uri.parse('$baseUrl/Carts/update-quantity'),
        headers: headers,
        body: jsonEncode({
          'maTaiKhoan': user.maTaiKhoan,
          'maSanPham': productId,
          'soLuong': quantity,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to update cart item');
      }
    } catch (e) {
      throw Exception('Error updating cart item: $e');
    }
  }

  Future<bool> clearCart() async {
    try {
      final headers = await getHeaders();
      final user = await getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      final response = await http.delete(
        Uri.parse('$baseUrl/Carts/clear/${user.maTaiKhoan}'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to clear cart');
      }
    } catch (e) {
      throw Exception('Error clearing cart: $e');
    }
  }

  // ==================== CATEGORIES ====================

  Future<List<Category>> getCategories() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/Category'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('Categories API Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Found ${data.length} categories');
        
        return data.map((e) => Category.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting categories: $e');
      throw Exception('Error getting categories: $e');
    }
  }

Future<bool> addCategory(String tenDanhMuc, File? iconFile) async {
  try {
    var request = http.MultipartRequest(
      'POST', 
      Uri.parse('$baseUrl/Category')
    );
    
    // Thêm các trường dữ liệu
    request.fields['TenDanhMuc'] = tenDanhMuc;
    
    // Thêm file ảnh nếu có
    if (iconFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'IconFile', 
        iconFile.path
      ));
    }
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(responseData);
      return jsonResponse['message'] == 'Thêm danh mục thành công';
    }
    return false;
  } catch (e) {
    throw Exception('Lỗi thêm danh mục: $e');
  }
}

Future<bool> updateCategory(String id, String tenDanhMuc, File? iconFile, {String? currentIconPath}) async {
  try {
    var request = http.MultipartRequest(
      'PUT', 
      Uri.parse('$baseUrl/Category/$id')
    );
    
    // Thêm các trường dữ liệu
    request.fields['TenDanhMuc'] = tenDanhMuc;
    if (currentIconPath != null) {
      request.fields['CurrentIconPath'] = currentIconPath;
    }
    
    // Thêm file ảnh nếu có
    if (iconFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'IconFile', 
        iconFile.path
      ));
    }
    
    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(responseData);
      return jsonResponse['message'] == 'Cập nhật danh mục thành công';
    }
    return false;
  } catch (e) {
    throw Exception('Lỗi cập nhật danh mục: $e');
  }
}

Future<bool> deleteCategory(String id) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/Category/$id'),
    );
    
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['message'] == 'Xóa danh mục thành công';
    } else if (response.statusCode == 400) {
      final jsonResponse = json.decode(response.body);
      throw Exception(jsonResponse['error'] ?? 'Không thể xóa danh mục');
    }
    return false;
  } catch (e) {
    throw Exception('Lỗi xóa danh mục: $e');
  }
}
  Future<Category?> getCategoryById(String categoryId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/Category/$categoryId'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Category.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting category: $e');
      return null;
    }
  }

  Future<List<Category>> searchCategories(String keyword) async {
    try {
      final headers = await getHeaders();
      final encodedKeyword = Uri.encodeComponent(keyword);
      
      final response = await http.get(
        Uri.parse('$baseUrl/Category/search/$encodedKeyword'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Category.fromJson(e)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error searching categories: $e');
      return [];
    }
  }

Future<List<Product>> getProductsByCategory(String categoryId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/Category/$categoryId/products'),
      headers: await getHeaders(),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      
      // Xử lý URL ảnh trước khi tạo Product
      final processedData = data.map((item) {
        if (item['anh'] != null && item['anh'].contains('localhost')) {
          item['anh'] = item['anh'].replaceAll('localhost', '10.0.2.2');
        }
        return item;
      }).toList();
      
      return processedData.map((e) => Product.fromJson(e)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Failed to load products: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error getting products by category: $e');
  }
}


  // ==================== ORDER ====================
Future<List<Order>> getOrders() async {
  final res = await http.get(Uri.parse('$baseUrl/Orders'));
  if (res.statusCode == 200) {
    final dynamic data = jsonDecode(res.body);
    
    // Kiểm tra nếu data là Map và có key chứa danh sách orders
    if (data is Map<String, dynamic>) {
      // Tìm key chứa danh sách orders (có thể là 'data', 'orders', 'items', v.v.)
      if (data.containsKey('data') && data['data'] is List) {
        final List<dynamic> orderList = data['data'];
        return orderList.map((e) => Order.fromJson(e)).toList();
      } else if (data.containsKey('orders') && data['orders'] is List) {
        final List<dynamic> orderList = data['orders'];
        return orderList.map((e) => Order.fromJson(e)).toList();
      } else if (data.containsKey('items') && data['items'] is List) {
        final List<dynamic> orderList = data['items'];
        return orderList.map((e) => Order.fromJson(e)).toList();
      } else {
        // Nếu không tìm thấy key nào phù hợp, thử lấy giá trị đầu tiên là List
        final dynamic firstValue = data.values.first;
        if (firstValue is List) {
          return firstValue.map((e) => Order.fromJson(e)).toList();
        } else {
          throw Exception('Cấu trúc dữ liệu không hợp lệ: $data');
        }
      }
    } 
    // Nếu data là List thì xử lý bình thường
    else if (data is List) {
      return data.map((e) => Order.fromJson(e)).toList();
    } 
    else {
      throw Exception('Định dạng dữ liệu không hợp lệ: ${data.runtimeType}');
    }
  } else {
    throw Exception('Không thể tải danh sách đơn hàng: ${res.statusCode}');
  }
}

// Cập nhật trạng thái đơn hàng
Future<bool> updateOrderStatus(String orderId, String status) async {
  try {
    final headers = await getHeaders();
    
    final requestData = {
      'trangThai': status,
    };

    print('🔄 Updating order status: $orderId -> $status');

    final response = await http.put(
      Uri.parse('$baseUrl/Orders/$orderId/status'),
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestData),
    ).timeout(const Duration(seconds: 30));

    print('📦 Update Order Status API Response: ${response.statusCode}');
    print('📦 Update Order Status API Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Order status updated successfully: $data');
      return true;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to update order status: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error updating order status: $e');
    throw Exception('Error updating order status: $e');
  }
}

  Future<bool> createOrder(Order order, List<OrderDetail> orderDetails) async {
    try {
      final headers = await getHeaders();
      
      final requestData = {
        'order': order.toJson(),
        'orderDetails': orderDetails.map((detail) => detail.toJson()).toList(),
      };

      print('🛒 Creating order with data: $requestData');

      final response = await http.post(
        Uri.parse('$baseUrl/Orders'),
        headers: headers,
        body: jsonEncode(requestData),
      ).timeout(const Duration(seconds: 30));

      print('📦 Create Order API Response: ${response.statusCode}');
      print('📦 Create Order API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Order created successfully: $data');
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating order: $e');
      throw Exception('Error creating order: $e');
    }
  }



  // Lấy danh sách đơn hàng của user
  Future<List<Order>> getOrdersByUser() async {
    try {
      final headers = await getHeaders();
      final user = await getCurrentUser();
      
      if (user == null) throw Exception('User not logged in');

      print('Fetching orders for user: ${user.maTaiKhoan}');
      final response = await http.get(
        Uri.parse('$baseUrl/Orders/user/${user.maTaiKhoan}'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('Orders API Response: ${response.statusCode}');
      print('Orders API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Orders API Data: $data');
        
        // Kiểm tra cấu trúc response
        if (data is Map && data.containsKey('data')) {
          final List<dynamic> ordersData = data['data'];
          print('Found ${ordersData.length} orders for user: ${user.maTaiKhoan}');
          
          return ordersData.map((e) => Order.fromJson(e)).toList();
        } else {
          print('Unexpected response structure: $data');
          return [];
        }
      } else if (response.statusCode == 404) {
        print('No orders found for user: ${user.maTaiKhoan}');
        return [];
      } else {
        print('Failed to load orders: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting orders: $e');
      throw Exception('Error getting orders: $e');
    }
  }

  // Lấy số lượng đơn hàng bằng cách đếm từ danh sách
  Future<int> getOrderCount() async {
    try {
      final orders = await getOrdersByUser();
      return orders.length;
    } catch (e) {
      print('Error getting order count: $e');
      return 0;
    }
  }

  // Lấy chi tiết đơn hàng
  Future<Map<String, dynamic>> getOrderDetail(String orderId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/Orders/$orderId'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('Order Detail API Response: ${response.statusCode}');
      print('Order Detail API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Order Detail API Data: $data');
        
        // Kiểm tra cấu trúc response
        if (data is Map && data.containsKey('data')) {
          return data['data']; // Trả về data chứa order và orderDetails
          
        } else {
          print('Unexpected order detail response structure: $data');
          throw Exception('Unexpected response structure');
        }
      } else {
        throw Exception('Failed to load order detail: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting order detail: $e');
      throw Exception('Error getting order detail: $e');
    }
  }

  Future isAdmin() async {}



// ==================== RATINGS ====================
// Lấy tất cả đánh giá
Future<List<Rating>> getRatings() async {
  try {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/Ratings'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Rating.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load ratings: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error loading ratings: $e');
  }
}

// Lấy đánh giá theo sản phẩm
Future<List<Rating>> getRatingsByProduct(String maSanPham) async {
  try {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/Ratings/$maSanPham'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Rating.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      return []; // Không có đánh giá nào
    } else {
      throw Exception('Failed to load product ratings: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error loading product ratings: $e');
  }
}

// Thêm đánh giá mới
Future<bool> addRating(Rating rating) async {
  try {
    final headers = await getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/Ratings'),
      headers: headers,
      body: json.encode(rating.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 400) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to add rating');
    } else {
      throw Exception('Failed to add rating: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error adding rating: $e');
  }
}

// Lấy thống kê đánh giá sản phẩm
Future<RatingStats> getProductRatingStats(String maSanPham) async {
  try {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/Ratings/product/$maSanPham/average'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return RatingStats.fromJson(data);
    } else {
      throw Exception('Failed to load rating stats: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error loading rating stats: $e');
  }
}

// Kiểm tra xem user đã đánh giá sản phẩm chưa
Future<bool> hasUserRatedProduct(String maSanPham) async {
  try {
    final user = await getCurrentUser();
    if (user == null) return false;

    final ratings = await getRatingsByProduct(maSanPham);
    return ratings.any((rating) => rating.maTaiKhoan == user.maTaiKhoan);
  } catch (e) {
    print('Error checking user rating: $e');
    return false;
  }
}

// Lấy đánh giá của user cho sản phẩm cụ thể
Future<Rating?> getUserRatingForProduct(String maSanPham) async {
  try {
    final user = await getCurrentUser();
    if (user == null) return null;

    final ratings = await getRatingsByProduct(maSanPham);
    return ratings.firstWhere(
      (rating) => rating.maTaiKhoan == user.maTaiKhoan,
      orElse: () => Rating(
        maSanPham: maSanPham,
        maTaiKhoan: user.maTaiKhoan,
        soSao: 0,
      ),
    );
  } catch (e) {
    print('Error getting user rating: $e');
    return null;
  }
}

// Cập nhật đánh giá
Future<bool> updateRating(Rating rating) async {
  try {
    final headers = await getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/Ratings'),
      headers: headers,
      body: json.encode(rating.toJson()),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to update rating: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error updating rating: $e');
  }
}

// Xóa đánh giá
Future<bool> deleteRating(String maSanPham) async {
  try {
    final headers = await getHeaders();
    final user = await getCurrentUser();
    
    if (user == null) throw Exception('User not logged in');

    final response = await http.delete(
      Uri.parse('$baseUrl/Ratings/$maSanPham/${user.maTaiKhoan}'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Failed to delete rating: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Error deleting rating: $e');
  }
}



//===================== COUPONS ====================
 // GET: Lấy tất cả phiếu giảm giá
  Future<List<PhieuGiamGia>> getAllCoupons() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/Coupon'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('Coupons API Response: ${response.statusCode}');
      print('Coupons API Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Found ${data.length} coupons');
        
        return data.map((e) => PhieuGiamGia.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load coupons: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting coupons: $e');
      throw Exception('Error getting coupons: $e');
    }
  }

  // GET: Tìm kiếm phiếu giảm giá theo code
  Future<List<PhieuGiamGia>> searchCoupons(String code) async {
    try {
      final headers = await getHeaders();
      final encodedCode = Uri.encodeComponent(code);
      
      final response = await http.get(
        Uri.parse('$baseUrl/Coupon/Search?code=$encodedCode'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('Search Coupons API Response: ${response.statusCode}');
      print('Search Coupons URL: $baseUrl/Coupon/Search?code=$encodedCode');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Found ${data.length} coupons for code: $code');
        
        return data.map((e) => PhieuGiamGia.fromJson(e)).toList();
      } else if (response.statusCode == 404) {
        print('No coupons found for code: $code');
        return [];
      } else {
        throw Exception('Failed to search coupons: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching coupons: $e');
      throw Exception('Error searching coupons: $e');
    }
  }

  // GET: Lấy phiếu giảm giá theo ID
  Future<PhieuGiamGia> getCouponById(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/Coupon/$id'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('Coupon by ID API Response: ${response.statusCode}');
      print('Coupon by ID API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PhieuGiamGia.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy phiếu giảm giá');
      } else {
        throw Exception('Failed to load coupon: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting coupon by ID: $e');
      throw Exception('Error getting coupon by ID: $e');
    }
  }

  // GET: Lấy phiếu giảm giá theo mã code
  Future<PhieuGiamGia> getCouponByCode(String code) async {
    try {
      final headers = await getHeaders();
      final encodedCode = Uri.encodeComponent(code);
      
      final response = await http.get(
        Uri.parse('$baseUrl/Coupon/Code/$encodedCode'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('Coupon by Code API Response: ${response.statusCode}');
      print('Coupon by Code API Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PhieuGiamGia.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy phiếu giảm giá với mã này');
      } else {
        throw Exception('Failed to load coupon by code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting coupon by code: $e');
      throw Exception('Error getting coupon by code: $e');
    }
  }

// POST: Thêm phiếu giảm giá mới
Future<String> createCoupon(PhieuGiamGia coupon) async {
  final headers = await getHeaders();
  final requestData = {
    'code': coupon.code,
    'giaTri': coupon.giaTri,
    'moTa': coupon.moTa,
  };

  final response = await http.post(
    Uri.parse('$baseUrl/Coupon'),
    headers: headers,
    body: jsonEncode(requestData),
  ).timeout(const Duration(seconds: 30));

  if (response.statusCode == 200) {
    return "Thêm thành công";
  } else {
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? 'Thêm phiếu giảm giá thất bại');
  }
}

// PUT: Cập nhật phiếu giảm giá
Future<String> updateCoupon(String id, PhieuGiamGia coupon) async {
  final headers = await getHeaders();
  final requestData = {
    'code': coupon.code,
    'giaTri': coupon.giaTri,
    'moTa': coupon.moTa,
  };

  final response = await http.put(
    Uri.parse('$baseUrl/Coupon/$id'),
    headers: headers,
    body: jsonEncode(requestData),
  ).timeout(const Duration(seconds: 30));

  if (response.statusCode == 200) {
    return "Cập nhật thành công";
  } else if (response.statusCode == 404) {
    throw Exception('Không tìm thấy phiếu giảm giá để cập nhật');
  } else {
    final errorData = jsonDecode(response.body);
    throw Exception(errorData['error'] ?? 'Cập nhật phiếu giảm giá thất bại');
  }
}

  // DELETE: Xóa phiếu giảm giá
  Future<bool> deleteCoupon(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/Coupon/$id'));
    return res.statusCode == 200;
  }

  // Kiểm tra tính hợp lệ của phiếu giảm giá
  Future<bool> validateCoupon(String code) async {
    try {
      final coupon = await getCouponByCode(code);
      return coupon.idPhieuGiamGia.isNotEmpty;
    } catch (e) {
      print('Coupon validation failed: $e');
      return false;
    }
  }

  // Áp dụng phiếu giảm giá vào đơn hàng
  Future<double> applyCouponToOrder(String code, double totalAmount) async {
    try {
      final coupon = await getCouponByCode(code);
      
      if (coupon.idPhieuGiamGia.isEmpty) {
        throw Exception('Mã giảm giá không hợp lệ');
      }

      // Tính toán số tiền giảm giá
      double discountAmount = coupon.giaTri;
      
      // Nếu giá trị giảm giá là phần trăm (giả sử nếu giá trị > 100 là phần trăm)
      if (coupon.giaTri > 0 && coupon.giaTri <= 100) {
        discountAmount = totalAmount * (coupon.giaTri / 100);
      }

      // Đảm bảo số tiền giảm không vượt quá tổng đơn hàng
      if (discountAmount > totalAmount) {
        discountAmount = totalAmount;
      }

      return discountAmount;
    } catch (e) {
      print('Error applying coupon: $e');
      throw Exception('Không thể áp dụng mã giảm giá: $e');
    }
  }

  // Lấy số lượng phiếu giảm giá
  Future<int> getCouponCount() async {
    try {
      final coupons = await getAllCoupons();
      return coupons.length;
    } catch (e) {
      print('Error getting coupon count: $e');
      return 0;
    }
  }

  // Kiểm tra xem mã giảm giá có tồn tại không (dùng cho validation)
  Future<bool> checkCouponExists(String code) async {
    try {
      final coupons = await searchCoupons(code);
      return coupons.isNotEmpty;
    } catch (e) {
      print('Error checking coupon existence: $e');
      return false;
    }
  }


//===================== PAY ===================
Future<List<Pay>> getPay() async {
  try {
    final headers = await getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/Pay'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    print('Pay API Response: ${response.statusCode}');
    print('Pay API Body: ${response.body}');
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print('Found ${data.length} pay methods');
      
      if (data.isEmpty) {
        throw Exception('No pay methods available');
      }
      
      return data.map((e) => Pay.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load pay methods: ${response.statusCode}');
    }
  } catch (e) {
    print('Error getting pay methods: $e');
    throw Exception('Error getting pay methods: $e');
  }
}


}