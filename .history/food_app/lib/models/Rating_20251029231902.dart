class Rating {
  final String maSanPham;
  final String maTaiKhoan;
  final String maDonHang;
  final String? noiDung;
  final int soSao;

  Rating({
    required this.maSanPham,
    required this.maTaiKhoan,
    required this.maDonHang,
    this.noiDung,
    required this.soSao,
  });

  Map<String, dynamic> toJson() {
    return {
      'maSanPham': maSanPham,
      'maTaiKhoan': maTaiKhoan,
      'maDonHang': maDonHang,
      'noiDung': noiDung,
      'soSao': soSao,
    };
  }

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      maSanPham: json['maSanPham'] ?? '',
      maTaiKhoan: json['maTaiKhoan'] ?? '',
      maDonHang: json['maDonHang'] ?? '',
      noiDung: json['noiDung'],
      soSao: json['soSao'] ?? 0,
    );
  }
}

class RatingStats {
  final double averageRating;
  final int totalRatings;

  RatingStats({
    required this.averageRating,
    required this.totalRatings,
  });

  factory RatingStats.fromJson(Map<String, dynamic> json) {
    return RatingStats(
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
    );
  }
}