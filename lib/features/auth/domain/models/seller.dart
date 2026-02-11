class Seller {
  final String uid;
  final String businessName;
  final String mpesaNumber;
  final bool isVerified;
  final double rating;
  final int reviewCount;

  Seller({
    required this.uid,
    required this.businessName,
    required this.mpesaNumber,
    this.isVerified = false,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'businessName': businessName,
      'mpesaNumber': mpesaNumber,
      'isVerified': isVerified,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  factory Seller.fromMap(Map<String, dynamic> map) {
    return Seller(
      uid: map['uid'] ?? '',
      businessName: map['businessName'] ?? '',
      mpesaNumber: map['mpesaNumber'] ?? '',
      isVerified: map['isVerified'] ?? false,
      rating: (map['rating'] as num? ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
    );
  }
}
