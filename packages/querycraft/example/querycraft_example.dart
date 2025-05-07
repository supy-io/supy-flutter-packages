import 'dart:convert';

import 'package:querycraft/querycraft.dart';

void main() async {
  final query = ApiQuery(
    filtering: and(
      filters: [
        where('category', QueryOperation.inclusion, ['electronics', 'books']),
        where('price', QueryOperation.lte, 500),
        where('title', QueryOperation.contains, 'smart'),
      ],
      groups: [
        or(
          filters: [
            where('rating', QueryOperation.gte, 4.0),
            where('is_featured', QueryOperation.eq, true),
          ],
        ),
      ],
    ),
    ordering: [
      ordering('price', QueryOrderDirection.desc),
      ordering('created_at', QueryOrderDirection.asc),
    ],
    paging: paginate(offset: 0, limit: 20),
    selection: include(['id', 'title', 'price', 'thumbnail']),
  );

  // 2. Convert to API-ready format
  final queryParams = query.toMap();
  print('Query Parameters: $queryParams');

  // 3. Execute API request
  // try {
  //   final response = await http.get(
  //     Uri.https('api.example.com', '/products', queryParams),
  //   );
  //
  //   // 4. Parse response
  //   final apiResponse = ApiQueryResponse<Product>.(
  //     jsonDecode(response.body),
  //     (data) => Product.fromJson(data),
  //   );
  //
  //   print('Total products: ${apiResponse.metadata.total}');
  //   print('First product: ${apiResponse.data.first}');
  // } catch (e) {
  //   print('Error fetching products: $e');
  // }
}

// Product model
class Product {
  final String id;
  final String title;
  final double price;
  final String thumbnail;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.thumbnail,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
      price: json['price'].toDouble(),
      thumbnail: json['thumbnail'],
    );
  }

  @override
  String toString() => 'Product($title, \$$price)';
}
