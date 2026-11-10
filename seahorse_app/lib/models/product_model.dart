class ProductModel {
  final int id;
  final String productCode;
  final String title;
  final String category;
  final double price;
  final double cost;
  final int durationMinutes;
  final String type; // SERVICE (服务项目) | RETAIL (实物商品)
  final String description;
  final int stock;
  final String unit;
  final bool available;

  ProductModel({
    required this.id,
    required this.productCode,
    required this.title,
    required this.category,
    required this.price,
    this.cost = 0.0,
    this.durationMinutes = 60,
    this.type = 'SERVICE',
    this.description = '',
    this.stock = 99,
    this.unit = '次',
    this.available = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    String pType = json['productType'] ?? json['type'] ?? 'PHYSICAL';
    if (pType == 'RETAIL') pType = 'PHYSICAL';

    final int parsedId = json['id'] is int
        ? json['id']
        : (int.tryParse(json['id']?.toString() ?? '0') ?? 0);

    final double parsedPrice = json['price'] is num
        ? (json['price'] as num).toDouble()
        : (double.tryParse(json['price']?.toString() ?? json['salePrice']?.toString() ?? '0') ?? 0.0);

    final double parsedCost = json['costPrice'] is num
        ? (json['costPrice'] as num).toDouble()
        : (double.tryParse(json['costPrice']?.toString() ?? json['cost']?.toString() ?? '0') ?? 0.0);

    final int parsedStock = json['stock'] is int
        ? json['stock']
        : (int.tryParse(json['stock']?.toString() ?? '') ?? (pType == 'SERVICE' ? 999 : 50));

    final int parsedDuration = json['durationMinutes'] is int
        ? json['durationMinutes']
        : (int.tryParse(json['durationMinutes']?.toString() ?? '') ?? (pType == 'SERVICE' ? 30 : 0));

    return ProductModel(
      id: parsedId,
      productCode: json['productCode'] ?? json['code'] ?? '',
      title: json['name'] ?? json['title'] ?? json['productTitle'] ?? '',
      category: json['categoryName'] ?? json['category'] ?? '通用商品',
      price: parsedPrice,
      cost: parsedCost,
      durationMinutes: parsedDuration,
      type: pType,
      description: json['description'] ?? json['spec'] ?? '',
      stock: parsedStock,
      unit: json['unit'] ?? (pType == 'SERVICE' ? '次' : '件'),
      available: json['available'] ?? json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    String pType = type;
    if (pType == 'RETAIL') pType = 'PHYSICAL';
    return {
      if (id > 0) 'id': id,
      'productCode': productCode,
      'name': title,
      'title': title,
      'categoryName': category,
      'category': category,
      'productType': pType,
      'price': price,
      'costPrice': cost,
      'cost': cost,
      'durationMinutes': durationMinutes,
      'type': pType,
      'description': description,
      'stock': stock,
      'unit': unit,
      'available': available,
    };
  }

  bool get isPhysical => type == 'PHYSICAL' || type == 'RETAIL' || type == 'MATERIAL';
  bool get isService => type == 'SERVICE';
  String get categoryName => category;

  ProductModel copyWith({
    int? id,
    String? productCode,
    String? title,
    String? category,
    double? price,
    double? cost,
    int? durationMinutes,
    String? type,
    String? description,
    int? stock,
    String? unit,
    bool? available,
  }) {
    return ProductModel(
      id: id ?? this.id,
      productCode: productCode ?? this.productCode,
      title: title ?? this.title,
      category: category ?? this.category,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      type: type ?? this.type,
      description: description ?? this.description,
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      available: available ?? this.available,
    );
  }
}
