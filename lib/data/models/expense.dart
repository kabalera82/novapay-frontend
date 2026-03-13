// lib/data/models/expense.dart

enum ExpenseCategory {
  compras,
  facturas,
  personal,
  otro;

  String get label => switch (this) {
        ExpenseCategory.compras  => 'Compras',
        ExpenseCategory.facturas => 'Facturas',
        ExpenseCategory.personal => 'Personal',
        ExpenseCategory.otro     => 'Otro',
      };

  static ExpenseCategory fromName(String name) =>
      ExpenseCategory.values.firstWhere(
        (e) => e.name == name,
        orElse: () => ExpenseCategory.otro,
      );
}

class Expense {
  final int             id;
  final DateTime        date;
  final double          amount;
  final ExpenseCategory category;
  final String          description;
  final int             productId;    // 0 = sin producto
  final String          productName;
  final int             quantity;     // 0 = sin cantidad

  const Expense({
    required this.id,
    required this.date,
    required this.amount,
    required this.category,
    this.description  = '',
    this.productId    = 0,
    this.productName  = '',
    this.quantity     = 0,
  });

  Map<String, dynamic> toJson() => {
        'id':          id,
        'date':        date.toIso8601String(),
        'amount':      amount,
        'category':    category.name,
        'description': description,
        'productId':   productId,
        'productName': productName,
        'quantity':    quantity,
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id:          json['id'] as int,
        date:        DateTime.parse(json['date'] as String),
        amount:      (json['amount'] as num).toDouble(),
        category:    ExpenseCategory.fromName(json['category'] as String),
        description: json['description'] as String? ?? '',
        productId:   json['productId'] as int? ?? 0,
        productName: json['productName'] as String? ?? '',
        quantity:    json['quantity'] as int? ?? 0,
      );

  Expense copyWith({int? id}) => Expense(
        id:          id ?? this.id,
        date:        date,
        amount:      amount,
        category:    category,
        description: description,
        productId:   productId,
        productName: productName,
        quantity:    quantity,
      );
}
