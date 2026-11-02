import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_colors.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/common_screen_app_bar.dart';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _search = TextEditingController();
  late Future<List<OrderModel>> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<OrderModel>> _load() async {
    final response = await ApiService.instance.get(
      ApiConstants.orders,
      queryParameters: {
        'tab': 'all',
        if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
        'per_page': 100,
      },
    );
    final root = response.data is Map
        ? Map<String, dynamic>.from(response.data)
        : <String, dynamic>{};
    dynamic data = root['data'] ?? root['orders'];
    if (data is Map) data = data['orders'] ?? data['data'];
    if (data is Map) data = data['data'] ?? data['orders'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _create() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
    );
    if (mounted) _reload();
  }

  Future<void> _view(OrderModel order) async {
    // Do not reload the whole orders list while returning from details. That
    // request replaces the existing list with a loading Future and makes the
    // back navigation feel stuck. The list can be refreshed explicitly when
    // needed, and the detail screen already shows the latest order state.
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
    );
  }

  Future<void> _edit(OrderModel order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateOrderScreen(order: order)),
    );
    if (mounted) _reload();
  }

  Future<void> _delete(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete order?'),
        content: Text(
          'This will remove ${order.orderNo.isEmpty ? 'this order' : order.orderNo} from the order list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.dangerRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.instance.delete(
        ApiConstants.orderDelete.replaceFirst('{id}', order.id),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order deleted')));
        _reload();
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to delete order: $error')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      bottomNavigationBar: const PrimaryBottomNavigation(
        currentTab: AppBottomNavTab.profile,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: compact ? 8 : 10),
              CommonTopBar(title: 'Orders', compact: compact),
              SizedBox(height: compact ? 12 : 16),
              Expanded(
                child: FutureBuilder<List<OrderModel>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting)
                      return const Center(child: CircularProgressIndicator());
                    if (snapshot.hasError)
                      return _ErrorState(
                        message: snapshot.error.toString(),
                        onRetry: _reload,
                      );
                    final orders = snapshot.data ?? const <OrderModel>[];
                    return RefreshIndicator(
                      onRefresh: () async => _reload(),
                      child: ListView(
                        padding: const EdgeInsets.only(top: 16, bottom: 28),
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Order workspace',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryText,
                                  ),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _create,
                                icon: const Icon(Icons.add),
                                label: const Text('New order'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _search,
                            onSubmitted: (_) => _reload(),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Search orders, clients or vendors',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  _search.clear();
                                  _reload();
                                },
                                icon: const Icon(Icons.clear),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (orders.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(
                                child: Text(
                                  'No orders found.',
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                  ),
                                ),
                              ),
                            )
                          else
                            ...orders.map(
                              (order) => _OrderCard(
                                order: order,
                                compact: compact,
                                onView: () => _view(order),
                                onEdit: () => _edit(order),
                                onDelete: () => _delete(order),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.compact,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });
  final OrderModel order;
  final bool compact;
  final VoidCallback onView, onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final client = order.clientName.isEmpty
        ? 'Client unavailable'
        : order.clientName;
    final vendor = order.vendorName.isEmpty
        ? 'Vendor unavailable'
        : order.vendorName;
    return InkWell(
      onTap: onView,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5ECF5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 42 : 46,
                  height: compact ? 42 : 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primaryBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNo.isEmpty
                            ? 'Order ${order.id}'
                            : order.orderNo,
                        style: TextStyle(
                          fontSize: compact ? 13.5 : 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryText,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        client,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                _Status(text: order.overallStatus),
              ],
            ),
            SizedBox(height: compact ? 10 : 12),
            Row(
              children: [
                Expanded(
                  child: _OrderInfo(
                    icon: Icons.storefront_outlined,
                    text: vendor,
                    compact: compact,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OrderInfo(
                    icon: Icons.calendar_today_outlined,
                    text: order.orderDate.split('T').first,
                    compact: compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 6,
              children: [
                _Status(text: 'Purchase: ${order.purchaseStatus}'),
                _Status(text: 'Delivery: ${order.deliveryStatus}'),
                _Status(text: order.priority),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEAF0F6)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Order actions',
                    style: TextStyle(
                      color: Color(0xFF4C5B70),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _OrderCardAction(
                  icon: Icons.visibility_outlined,
                  onTap: onView,
                ),
                const SizedBox(width: 6),
                _OrderCardAction(icon: Icons.edit_outlined, onTap: onEdit),
                const SizedBox(width: 6),
                _OrderCardAction(
                  icon: Icons.delete_outline_rounded,
                  onTap: onDelete,
                  destructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderInfo extends StatelessWidget {
  const _OrderInfo({
    required this.icon,
    required this.text,
    required this.compact,
  });
  final IconData icon;
  final String text;
  final bool compact;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: compact ? 15 : 16, color: const Color(0xFF64748B)),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF475569),
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}

class _OrderCardAction extends StatelessWidget {
  const _OrderCardAction({
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) => Material(
    color: destructive ? const Color(0xFFFEE4E2) : const Color(0xFFE8F0FE),
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(
          icon,
          color: destructive
              ? const Color(0xFFB42318)
              : const Color(0xFF1D4ED8),
          size: 18,
        ),
      ),
    ),
  );
}

class _Status extends StatelessWidget {
  const _Status({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF2FF),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 10.5,
        color: AppColors.primaryBlue,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Unable to load orders',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.secondaryText),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
