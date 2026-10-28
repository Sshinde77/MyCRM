import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_colors.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;
  @override State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Future<OrderModel> _future;
  bool _actionInProgress = false;
  bool _hasChanges = false;
  @override void initState() { super.initState(); _future = _load(); }

  String _path(String path) => path.replaceFirst('{id}', widget.orderId);

  Future<OrderModel> _load() async {
    final response = await ApiService.instance.get(_path(ApiConstants.orderDetail));
    final root = response.data is Map ? Map<String, dynamic>.from(response.data) : <String, dynamic>{};
    dynamic data = root['data'] ?? root;
    if (data is Map && data['order'] is Map) data = data['order'];
    return OrderModel.fromJson(data is Map ? Map<String, dynamic>.from(data) : {});
  }

  Future<void> _action(String endpoint, {Map<String, dynamic>? data}) async {
    if (_actionInProgress) return;

    setState(() => _actionInProgress = true);
    try {
      await ApiService.instance.post(_path(endpoint), data: data);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order updated successfully'),
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _hasChanges = true;
      setState(() {
        _future = _load();
      });
    } catch (error) {
      String message = 'Action failed';
      if (error is DioException) {
        final resData = error.response?.data;
        if (resData is Map) {
          message = resData['message']?.toString() ??
              resData['error']?.toString() ??
              error.message ??
              'Action failed';
        } else if (error.message != null && error.message!.isNotEmpty) {
          message = error.message!;
        }
      } else {
        message = error.toString();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  void _goBack() {
    if (!mounted) return;
    Navigator.of(context).pop(_hasChanges);
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(height: compact ? 8 : 10),
            CommonTopBar(title: 'Order details', compact: compact, onBack: _goBack),
            SizedBox(height: compact ? 12 : 16),
            Expanded(child: FutureBuilder<OrderModel>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return _MessageState(message: 'Unable to load order: ${snapshot.error}');
                final order = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _future = _load();
                    });
                  },
                  child: ListView(padding: const EdgeInsets.only(bottom: 28), children: [
                    _hero(order), const SizedBox(height: 12), _summary(order), const SizedBox(height: 12), _workflow(order), const SizedBox(height: 12), _items(order),
                    if (order.notes.isNotEmpty) ...[const SizedBox(height: 12), _notes(order.notes)],
                    if (order.history.isNotEmpty) ...[const SizedBox(height: 12), _history(order.history)],
                  ]),
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  Widget _hero(OrderModel order) => Card(
    color: AppColors.primaryBlue,
    child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.receipt_long_rounded, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('ORDER', style: TextStyle(color: Color(0xFFB9C9E2), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)), const SizedBox(height: 3), Text(order.orderNo.isEmpty ? 'Order ${order.id}' : order.orderNo, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800))])),
        _HeroStatus(text: order.overallStatus),
      ]),
      const SizedBox(height: 18),
      Row(children: [Expanded(child: _heroMeta(Icons.person_outline, order.clientName.isEmpty ? 'Client unavailable' : order.clientName)), const SizedBox(width: 12), Expanded(child: _heroMeta(Icons.storefront_outlined, order.vendorName.isEmpty ? 'Vendor unavailable' : order.vendorName))]),
    ])),
  );

  Widget _heroMeta(IconData icon, String value) => Row(children: [Icon(icon, size: 16, color: const Color(0xFFB9C9E2)), const SizedBox(width: 7), Expanded(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)))]);

  Widget _summary(OrderModel order) => _sectionCard('Order information', Icons.info_outline_rounded, Column(children: [
    Row(children: [Expanded(child: _detailTile('Order date', _displayDate(order.orderDate), Icons.calendar_today_outlined)), Expanded(child: _detailTile('Priority', order.priority, Icons.flag_outlined))]),
    const Divider(height: 24),
    Row(children: [Expanded(child: _detailTile('Vendor expected', _displayDate(order.vendorExpectedDate), Icons.local_shipping_outlined)), Expanded(child: _detailTile('Client delivery', _displayDate(order.clientDeliveryDate), Icons.event_available_outlined))]),
    if (order.ownerName.isNotEmpty) ...[const Divider(height: 24), _detailTile('Order owner', order.ownerName, Icons.person_outline)],
  ]));

  String _displayDate(String value) {
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) return value;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
  }

  Widget _detailTile(String label, String value, IconData icon) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(9)), child: Icon(icon, size: 16, color: AppColors.primaryBlue)), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)), const SizedBox(height: 3), Text(value.isEmpty ? '—' : value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w700))]))]);

  Widget _workflow(OrderModel order) {
    final priorityLabel = '${order.priority.isNotEmpty ? order.priority : 'Normal'} priority';
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Workflow status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Two independent tracks, one operational timeline.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    priorityLabel,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPurchaseTrackCard(order),
            const SizedBox(height: 14),
            _buildDeliveryTrackCard(order),
            const SizedBox(height: 14),
            Row(
              children: [
                if (order.isOnHold)
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0D9488),
                        side: const BorderSide(color: Color(0xFF5EEAD4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _action(ApiConstants.orderHold),
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Resume Order', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () => _action(ApiConstants.orderHold),
                      icon: const Icon(Icons.pause_circle_outline, size: 18),
                      label: const Text('Put on hold', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                if (order.overallStatus != 'Cancelled') ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dangerRed,
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: _cancel,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancel order', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseTrackCard(OrderModel order) {
    const purchaseStages = ['Draft', 'Ordered', 'Partially Received', 'Received'];
    final activeIndex = _purchaseStepIndex(order.purchaseStatus);
    final vendorSubtitle = order.vendorName.isNotEmpty
        ? 'Goods received from ${order.vendorName}'
        : 'Goods received from vendor';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E6F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD6E6F7)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 20,
                  color: Color(0xFF176EE2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Purchase · vendor to us',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      vendorSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                order.purchaseStatus,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTrackStepper(purchaseStages, activeIndex),
          const SizedBox(height: 18),
          _buildPurchaseActionButtons(order),
        ],
      ),
    );
  }

  Widget _buildDeliveryTrackCard(OrderModel order) {
    const deliveryStages = ['Pending', 'Ready to Dispatch', 'Dispatched', 'Delivered'];
    final activeIndex = _deliveryStepIndex(order.deliveryStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F6FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4E0F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE4E0F8)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 20,
                  color: Color(0xFF176EE2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Delivery · us to client',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Complete the client handoff',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                order.deliveryStatus,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTrackStepper(deliveryStages, activeIndex),
          const SizedBox(height: 18),
          _buildDeliveryActionButtons(order),
        ],
      ),
    );
  }

  Widget _buildTrackStepper(List<String> stages, int activeIndex) {
    const activeColor = Color(0xFF176EE2);
    const inactiveLineColor = Color(0xFFCBD5E1);
    const inactiveCircleColor = Color(0xFFEDF2F7);
    const inactiveTextColor = Color(0xFF94A3B8);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < stages.length; i++) ...[
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == 0
                            ? Colors.transparent
                            : (i <= activeIndex ? activeColor : inactiveLineColor),
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= activeIndex ? activeColor : inactiveCircleColor,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: i <= activeIndex ? Colors.white : inactiveTextColor,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 2,
                        color: i == stages.length - 1
                            ? Colors.transparent
                            : (i < activeIndex ? activeColor : inactiveLineColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    stages[i],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: i <= activeIndex ? activeColor : inactiveTextColor,
                      fontSize: 11,
                      fontWeight: i <= activeIndex ? FontWeight.w700 : FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPurchaseActionButtons(OrderModel order) {
    if (order.purchaseStatus == 'Draft') {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF176EE2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onPressed: () => _action(ApiConstants.orderPurchaseOrder),
        icon: const Icon(Icons.shopping_cart_checkout, size: 16),
        label: const Text('Mark as ordered', style: TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    if (order.purchaseStatus == 'Ordered' || order.purchaseStatus == 'Partially Received') {
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF176EE2),
              side: const BorderSide(color: Color(0xFF176EE2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => _showRecordReceiptDialog(order),
            child: const Text('Record receipt', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF176EE2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => _action(ApiConstants.orderPurchaseReceive),
            child: const Text('Mark all received', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      );
    }

    return Row(
      children: const [
        Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF059669)),
        SizedBox(width: 6),
        Text(
          'Purchase completed: All items received',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
        ),
      ],
    );
  }

  Widget _buildDeliveryActionButtons(OrderModel order) {
    if (order.deliveryStatus == 'Pending') {
      final canDispatch = order.purchaseStatus != 'Draft';
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: canDispatch ? const Color(0xFF176EE2) : const Color(0xFF94A3B8),
          side: BorderSide(color: canDispatch ? const Color(0xFF176EE2) : const Color(0xFFCBD5E1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onPressed: canDispatch ? () => _action(ApiConstants.orderDeliveryReady) : null,
        child: const Text('Mark Ready to Dispatch', style: TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    if (order.deliveryStatus == 'Ready to Dispatch') {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF176EE2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onPressed: () => _action(ApiConstants.orderDeliveryDispatch),
        icon: const Icon(Icons.local_shipping_outlined, size: 16),
        label: const Text('Dispatch', style: TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    if (order.deliveryStatus == 'Dispatched') {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onPressed: () => _action(ApiConstants.orderDeliveryDeliver),
        icon: const Icon(Icons.done_all_rounded, size: 16),
        label: const Text('Mark delivered', style: TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    return Row(
      children: const [
        Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF059669)),
        SizedBox(width: 6),
        Text(
          'Delivery completed: Handed off to client',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF059669)),
        ),
      ],
    );
  }

  int _purchaseStepIndex(String status) {
    switch (status.trim().toLowerCase()) {
      case 'draft':
        return 0;
      case 'ordered':
        return 1;
      case 'partially received':
      case 'partially_received':
        return 2;
      case 'received':
        return 3;
      default:
        return 0;
    }
  }

  int _deliveryStepIndex(String status) {
    switch (status.trim().toLowerCase()) {
      case 'pending':
        return 0;
      case 'ready to dispatch':
      case 'ready_to_dispatch':
        return 1;
      case 'dispatched':
        return 2;
      case 'delivered':
        return 3;
      default:
        return 0;
    }
  }

  Future<void> _showRecordReceiptDialog(OrderModel order) async {
    final controllers = <String, TextEditingController>{};
    for (final item in order.items) {
      // Send cumulative quantities so later receipts can be recorded.
      final initialVal = item.receivedQuantity;
      final defaultVal = initialVal == initialVal.roundToDouble()
          ? initialVal.toInt().toString()
          : initialVal.toString();
      controllers[item.id] = TextEditingController(text: defaultVal);
    }
    final remarkController = TextEditingController();
    DateTime receiptDate = DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Record Goods Receipt',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter the total quantity received so far for each item.',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    for (final item in order.items) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName.isEmpty ? 'Item' : item.productName,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Ordered: ${item.quantity} ${item.unit} | Received so far: ${item.receivedQuantity}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 95,
                                  child: TextField(
                                    controller: controllers[item.id],
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      labelText: 'Total Qty',
                                      isDense: true,
                                      border: const OutlineInputBorder(),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                      helperText: 'Max ${item.quantity}',
                                      helperStyle: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () {
                                    final maxVal = item.quantity == item.quantity.roundToDouble()
                                        ? item.quantity.toInt().toString()
                                        : item.quantity.toString();
                                    controllers[item.id]?.text = maxVal;
                                  },
                                  child: Text('Set Full (${item.quantity})', style: const TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    TextField(
                      controller: remarkController,
                      decoration: const InputDecoration(
                        labelText: 'Remark (Optional)',
                        hintText: 'e.g. Partial shipment received.',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF176EE2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          // Validate entered quantities
                          for (final item in order.items) {
                            final text = controllers[item.id]?.text.trim() ?? '';
                            final val = double.tryParse(text);
                            if (val == null || val < 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please enter a valid received quantity for "${item.productName.isEmpty ? 'Item' : item.productName}".'),
                                  backgroundColor: const Color(0xFFDC2626),
                                ),
                              );
                              return;
                            }
                            if (val > item.quantity) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Received quantity cannot exceed ordered quantity (${item.quantity}) for "${item.productName.isEmpty ? 'Item' : item.productName}".'),
                                  backgroundColor: const Color(0xFFDC2626),
                                ),
                              );
                              return;
                            }
                            if (val < item.receivedQuantity) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Received quantity cannot be less than the quantity already received (${item.receivedQuantity}) for "${item.productName.isEmpty ? 'Item' : item.productName}".'),
                                  backgroundColor: const Color(0xFFDC2626),
                                ),
                              );
                              return;
                            }
                          }

                          Navigator.of(context).pop();
                          final receivedMap = <String, dynamic>{
                            for (final item in order.items)
                              item.id: double.tryParse(controllers[item.id]?.text.trim() ?? '') ?? 0,
                          };

                          final isAllReceived = order.items.isNotEmpty &&
                              order.items.every((item) {
                                final qty = (receivedMap[item.id] as num?)?.toDouble() ?? 0;
                                return qty >= item.quantity;
                              });

                          final payload = <String, dynamic>{
                            'received': receivedMap,
                            'date': receiptDate.toIso8601String().split('T').first,
                            if (remarkController.text.trim().isNotEmpty)
                              'remark': remarkController.text.trim(),
                          };

                          final endpoint = isAllReceived
                              ? ApiConstants.orderPurchaseReceive
                              : order.purchaseStatus == 'Partially Received'
                                  ? ApiConstants.orderStatus
                                  : ApiConstants.orderPurchaseReceipt;
                          if (order.purchaseStatus == 'Partially Received' && !isAllReceived) {
                            payload['track'] = 'Purchase';
                            payload['status'] = 'Partially Received';
                          }

                          await _action(endpoint, data: payload);
                        },
                        child: const Text('Save Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    for (final c in controllers.values) {
      c.dispose();
    }
    remarkController.dispose();
  }

  Widget _items(OrderModel order) {
    final List<Widget> itemWidgets = order.items.map<Widget>((item) {
      final progress = item.quantity == 0 ? 0 : ((item.receivedQuantity / item.quantity) * 100).round();
      return Container(
        margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderColor)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.inventory_2_outlined, size: 18, color: AppColors.primaryBlue)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.productName.isEmpty ? 'Unnamed item' : item.productName, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryText)), const SizedBox(height: 5), Text('${item.quantity} ${item.unit} | Received ${item.receivedQuantity} | Delivered ${item.deliveredQuantity}', style: const TextStyle(fontSize: 11, color: AppColors.secondaryText))])),
          Text('$progress%', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primaryBlue)),
        ]),
      );
    }).toList();
    if (itemWidgets.isEmpty) itemWidgets.add(const Text('No items returned.', style: TextStyle(color: AppColors.secondaryText)));
    return _sectionCard('Items', Icons.inventory_2_outlined, Column(children: itemWidgets));
  }

  Widget _notes(String notes) => _sectionCard('Internal notes', Icons.sticky_note_2_outlined, Text(notes, style: const TextStyle(color: AppColors.primaryText, height: 1.45)));

  Widget _history(List<Map<String, dynamic>> history) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity history',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryText),
            ),
            const SizedBox(height: 16),
            ...List<Widget>.generate(history.length, (index) {
              final entry = history[index];
              final track = _historyValue(entry, 'track', fallback: 'Order');
              final status = _historyValue(entry, 'status');
              final toStatus = _historyValue(entry, 'to_status');
              final historyTitle = toStatus.isNotEmpty
                  ? toStatus
                  : (status.isNotEmpty ? status : track);
              final actor = _historyActor(entry);
              final date = _historyDate(entry['created_at']);
              final remark = _historyValue(entry, 'remark');

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 18,
                      child: Column(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
                          ),
                          if (index < history.length - 1)
                            Expanded(child: Container(width: 1, color: const Color(0xFFD5E3F5))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: index < history.length - 1 ? 18 : 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(historyTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryText)),
                            const SizedBox(height: 3),
                            Text('$track · $actor · $date', style: const TextStyle(fontSize: 10.5, color: AppColors.secondaryText)),
                            if (remark.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(remark, style: const TextStyle(fontSize: 12.5, color: AppColors.primaryText)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _historyValue(Map<String, dynamic> entry, String key, {String fallback = ''}) {
    final value = entry[key];
    return value == null || value.toString().trim().isEmpty ? fallback : value.toString();
  }

  String _historyActor(Map<String, dynamic> entry) {
    for (final key in ['user_name', 'actor_name', 'created_by_name', 'performed_by']) {
      final value = _historyValue(entry, key);
      if (value.isNotEmpty) return value;
    }
    final user = entry['user'];
    if (user is Map) {
      final name = user['name'] ?? user['full_name'] ?? user['email'];
      if (name != null && name.toString().isNotEmpty) return name.toString();
    }
    return 'Admin Team';
  }

  String _historyDate(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
    if (parsed == null) return value?.toString() ?? '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    final suffix = parsed.hour >= 12 ? 'PM' : 'AM';
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}, $hour:$minute $suffix';
  }

  Widget _sectionCard(String title, IconData icon, Widget child) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, size: 19, color: AppColors.primaryBlue), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryText))]), const SizedBox(height: 15), child])));

  Future<void> _cancel() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Cancel order'), content: TextField(controller: controller, maxLines: 3, decoration: const InputDecoration(labelText: 'Cancellation reason')), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel order'))]));
    if (confirmed == true && controller.text.trim().isNotEmpty) await _action(ApiConstants.orderCancel, data: {'cancel_reason': controller.text.trim()});
    controller.dispose();
  }
}

class _HeroStatus extends StatelessWidget {
  const _HeroStatus({required this.text});
  final String text;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)));
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.value});
  final String label, value;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFEAF2FF), borderRadius: BorderRadius.circular(10)), child: RichText(text: TextSpan(children: [TextSpan(text: '$label\n', style: const TextStyle(color: AppColors.secondaryText, fontSize: 10)), TextSpan(text: value, style: const TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.w700))])));
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message});
  final String message;
  @override Widget build(BuildContext context) => Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.secondaryText))));
}
