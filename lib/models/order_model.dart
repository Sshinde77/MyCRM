class OrderItemModel {
  const OrderItemModel({required this.id, required this.productName, required this.quantity, this.unit = '', this.receivedQuantity = 0, this.deliveredQuantity = 0, this.purchaseRate, this.sellingRate, this.remarks = ''});
  final String id, productName, unit, remarks;
  final double quantity, receivedQuantity, deliveredQuantity;
  final double? purchaseRate, sellingRate;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
    id: _s(json['id'] ?? json['item_id']),
    productName: _s(json['product_name'] ?? json['productName'] ?? json['name']),
    quantity: _d(json['quantity']),
    unit: _s(json['unit']),
    receivedQuantity: _d(json['qty_received'] ?? json['received_quantity'] ?? json['receivedQuantity']),
    deliveredQuantity: _d(json['qty_delivered'] ?? json['delivered_quantity'] ?? json['deliveredQuantity']),
    purchaseRate: _n(json['purchase_rate']),
    sellingRate: _n(json['selling_rate']),
    remarks: _s(json['remarks']),
  );
}

class OrderModel {
  const OrderModel({required this.id, required this.orderNo, required this.clientName, required this.vendorName, required this.orderDate, required this.vendorExpectedDate, required this.clientDeliveryDate, required this.purchaseStatus, required this.deliveryStatus, required this.overallStatus, required this.priority, required this.isOnHold, required this.items, this.clientId = '', this.vendorId = '', this.assignedUserId = '', this.ownerName = '', this.notes = '', this.history = const []});
  final String id, orderNo, clientName, vendorName, orderDate, vendorExpectedDate, clientDeliveryDate, purchaseStatus, deliveryStatus, overallStatus, priority, ownerName, notes;
  final String clientId, vendorId, assignedUserId;
  final bool isOnHold;
  final List<OrderItemModel> items;
  final List<Map<String, dynamic>> history;

  factory OrderModel.fromJson(Map<String, dynamic> raw) {
    final json = _map(raw['order'])..addAll(raw);
    final items = json['items'] is List ? (json['items'] as List).whereType<Map>().map((e) => OrderItemModel.fromJson(Map<String, dynamic>.from(e))).toList() : <OrderItemModel>[];
    final history = json['history'] is List ? (json['history'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : <Map<String, dynamic>>[];
    return OrderModel(id: _s(json['id']), orderNo: _s(json['order_no'] ?? json['orderNo']), clientName: _s(json['client_name'] ?? _nested(json['client'], 'name')), vendorName: _s(json['vendor_name'] ?? _nested(json['vendor'], 'vendor_name') ?? _nested(json['vendor'], 'name')), orderDate: _s(json['order_date']), vendorExpectedDate: _s(json['vendor_expected_date']), clientDeliveryDate: _s(json['client_delivery_date']), purchaseStatus: _s(json['purchase_status'], 'Draft'), deliveryStatus: _s(json['delivery_status'], 'Pending'), overallStatus: _s(json['overall_status'], 'Open'), priority: _s(json['priority'], 'Normal'), isOnHold: json['is_on_hold'] == true || json['is_on_hold'] == 1, items: items, clientId: _s(json['client_id']), vendorId: _s(json['vendor_id']), assignedUserId: _s(json['assigned_user_id']), ownerName: _s(json['owner_name'] ?? _nested(json['owner'], 'name') ?? _nested(json['assigned_user'], 'name')), notes: _s(json['notes']), history: history);
  }
}

String _s(dynamic value, [String fallback = '']) => value == null || value.toString() == 'null' ? fallback : value.toString();
double _d(dynamic value) => double.tryParse(_s(value)) ?? 0;
double? _n(dynamic value) => value == null ? null : double.tryParse(_s(value));
Map<String, dynamic> _map(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
dynamic _nested(dynamic value, String key) => value is Map ? value[key] : null;
