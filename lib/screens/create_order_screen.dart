import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/constants/app_colors.dart';
import '../models/client_model.dart';
import '../models/order_model.dart';
import '../models/staff_member_model.dart';
import '../models/vendor_model.dart';
import '../services/api_service.dart';
import '../widgets/common_screen_app_bar.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key, this.order});
  final OrderModel? order;
  @override State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _client = TextEditingController(), _vendor = TextEditingController(), _assigned = TextEditingController(), _notes = TextEditingController();
  final _orderDate = TextEditingController(text: _formatDate(DateTime.now()));
  final _vendorDate = TextEditingController(), _deliveryDate = TextEditingController();
  final _items = <_ItemDraft>[];
  List<ClientModel> _clients = const <ClientModel>[];
  List<VendorModel> _vendors = const <VendorModel>[];
  List<StaffMemberModel> _staff = const <StaffMemberModel>[];
  String? _selectedClientId, _selectedVendorId;
  String? _selectedStaffId;
  String _priority = 'Normal';
  bool _alreadyPlaced = false, _saving = false;

  bool get _isEditing => widget.order != null;

  @override
  void initState() {
    super.initState();
    _loadOptions();
    final order = widget.order;
    if (order == null) {
      _items.add(_ItemDraft());
      return;
    }
    _client.text = order.clientId;
    _vendor.text = order.vendorId;
    _selectedClientId = order.clientId.isEmpty ? null : order.clientId;
    _selectedVendorId = order.vendorId.isEmpty ? null : order.vendorId;
    _selectedStaffId = order.assignedUserId.isEmpty ? null : order.assignedUserId;
    _assigned.text = order.assignedUserId;
    _notes.text = order.notes;
    _orderDate.text = order.orderDate.split('T').first;
    _vendorDate.text = order.vendorExpectedDate.split('T').first;
    _deliveryDate.text = order.clientDeliveryDate.split('T').first;
    _priority = order.priority;
    _alreadyPlaced = order.purchaseStatus != 'Draft';
    _items.addAll(order.items.map(_ItemDraft.fromModel));
    if (_items.isEmpty) _items.add(_ItemDraft());
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([
        ApiService.instance.getClientsList(),
        ApiService.instance.getVendorsList(),
        ApiService.instance.getStaffList(),
      ]);
      if (!mounted) return;
      setState(() {
        _clients = results[0] as List<ClientModel>;
        _vendors = results[1] as List<VendorModel>;
        _staff = results[2] as List<StaffMemberModel>;
      });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to load clients and vendors: $error')));
    }
  }

  @override
  void dispose() {
    for (final controller in [_client, _vendor, _assigned, _notes, _orderDate, _vendorDate, _deliveryDate]) controller.dispose();
    for (final item in _items) item.dispose();
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final picked = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: DateTime.tryParse(controller.text) ?? DateTime.now());
    if (picked != null) setState(() => controller.text = _formatDate(picked));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'client_id': _selectedClientId ?? _client.text.trim(), 'vendor_id': _selectedVendorId ?? _vendor.text.trim(),
        if ((_selectedStaffId ?? _assigned.text.trim()).isNotEmpty) 'assigned_user_id': _selectedStaffId ?? _assigned.text.trim(),
        'order_date': _orderDate.text, 'vendor_expected_date': _vendorDate.text,
        'client_delivery_date': _deliveryDate.text, 'priority': _priority,
        'notes': _notes.text.trim(), 'already_placed': _alreadyPlaced,
        'items': _items.map((item) => item.toJson()).toList(),
      };
      if (_isEditing) {
        await ApiService.instance.put(ApiConstants.orderUpdate.replaceFirst('{id}', widget.order!.id), data: payload);
      } else {
        await ApiService.instance.post(ApiConstants.orders, data: payload);
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isEditing ? 'Order updated successfully' : 'Order created successfully'))); Navigator.pop(context, true); }
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Unable to create order: $error')));
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 360;
    return Scaffold(
    backgroundColor: AppColors.lightBackground,
    body: SafeArea(child: Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: compact ? 8 : 10),
        CommonTopBar(title: _isEditing ? 'Edit order' : 'Create order', compact: compact),
        SizedBox(height: compact ? 12 : 16),
        Expanded(child: Form(key: _formKey, child: ListView(padding: const EdgeInsets.only(bottom: 28), children: [
      _section('Order details', [
        _clientPicker(), _vendorPicker(), _staffPicker(),
        Row(children: [Expanded(child: _dateField(_orderDate, 'Order date')), const SizedBox(width: 10), Expanded(child: _dateField(_vendorDate, 'Vendor expected date'))]),
        Row(children: [
          Expanded(child: _dateField(_deliveryDate, 'Client delivery date')),
          const SizedBox(width: 10),
          Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 12), child: DropdownButtonFormField<String>(value: _priority, decoration: const InputDecoration(labelText: 'Priority'), items: const [DropdownMenuItem(value: 'Normal', child: Text('Normal')), DropdownMenuItem(value: 'High', child: Text('High'))], onChanged: (value) => setState(() => _priority = value ?? 'Normal')))),
        ]),
        _field(_notes, 'Internal notes', maxLines: 3),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Already placed with vendor'), subtitle: const Text('Starts purchase status as Ordered'), value: _alreadyPlaced, onChanged: _saving ? null : (value) => setState(() => _alreadyPlaced = value)),
      ]),
      const SizedBox(height: 16),
      _SectionTitle('Items'),
      const SizedBox(height: 10),
      ..._items.asMap().entries.map((entry) => _itemCard(entry.key, entry.value)),
      Align(alignment: Alignment.centerLeft, child: OutlinedButton.icon(onPressed: _saving ? null : () => setState(() => _items.add(_ItemDraft())), icon: const Icon(Icons.add), label: const Text('Add item'))),
      const SizedBox(height: 20),
      SizedBox(height: 48, child: FilledButton.icon(onPressed: _saving ? null : _submit, icon: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded), label: Text(_saving ? (_isEditing ? 'Saving changes...' : 'Creating order...') : (_isEditing ? 'Save changes' : 'Create order')))),
        ]))),
      ]),
    )),
  );
  }

  Widget _section(String title, List<Widget> children) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryText)), const SizedBox(height: 14), ...children])));
  Widget _clientPicker() => _pickerField('Client', _selectedClientId, _clients.map((client) => _PickerOption(client.id, client.name.isEmpty ? 'Client ${client.id}' : client.name)).toList(), (value) { _selectedClientId = value; _client.text = value ?? ''; });
  Widget _vendorPicker() => _pickerField('Vendor', _selectedVendorId, _vendors.map((vendor) => _PickerOption(vendor.id, vendor.vendorName.isEmpty ? 'Vendor ${vendor.id}' : vendor.vendorName)).toList(), (value) { _selectedVendorId = value; _vendor.text = value ?? ''; });
  Widget _staffPicker() => _pickerField('Assigned user', _selectedStaffId, _staff.map((member) => _PickerOption(member.id, member.name.isEmpty ? 'Staff ${member.id}' : member.name)).toList(), (value) { _selectedStaffId = value; _assigned.text = value ?? ''; }, required: false);

  Widget _pickerField(String label, String? selectedId, List<_PickerOption> options, ValueChanged<String?> onChanged, {bool required = true}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: FormField<String>(key: ValueKey('$label-$selectedId'), initialValue: selectedId, validator: required ? (value) => value == null || value.isEmpty ? 'Select $label'.toLowerCase() : null : null, builder: (state) {
    final selectedMatches = options.where((option) => option.id == selectedId);
    final selected = selectedMatches.isEmpty ? null : selectedMatches.first;
    return InkWell(onTap: () async { final value = await _showSearchPicker(label, options, selectedId); if (value == null) return; onChanged(value); state.didChange(value); setState(() {}); }, borderRadius: BorderRadius.circular(8), child: InputDecorator(decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded), errorText: state.errorText), child: Text(selected?.name ?? (options.isEmpty ? 'Loading...' : 'Select $label'), style: TextStyle(color: selected == null ? AppColors.secondaryText : AppColors.primaryText))));
  }));

  Future<String?> _showSearchPicker(String title, List<_PickerOption> options, String? selectedId) => showModalBottomSheet<String>(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => _SearchPickerSheet(title: title, options: options, selectedId: selectedId));
  Widget _itemCard(int index, _ItemDraft item) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                'Item ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primaryText),
              ),
              const Spacer(),
              if (_items.length > 1)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: _saving
                      ? null
                      : () {
                          final removed = _items.removeAt(index);
                          removed.dispose();
                          setState(() {});
                        },
                  icon: const Icon(Icons.delete_outline, color: AppColors.dangerRed),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _field(item.product, 'Product name', required: true),
          Row(children: [Expanded(child: _field(item.quantity, 'Quantity', required: true, number: true)), const SizedBox(width: 8), Expanded(child: _field(item.unit, 'Unit'))]),
          Row(children: [Expanded(child: _field(item.purchaseRate, 'Purchase rate', number: true)), const SizedBox(width: 8), Expanded(child: _field(item.sellingRate, 'Selling rate', number: true))]),
          _field(item.remarks, 'Remarks'),
        ],
      ),
    ),
  );
  Widget _dateField(TextEditingController controller, String label) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(controller: controller, readOnly: true, onTap: () => _pickDate(controller), decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today_outlined)), validator: (value) => value == null || value.isEmpty ? 'Required' : null));
  Widget _field(TextEditingController controller, String label, {bool required = false, bool number = false, int maxLines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextFormField(controller: controller, maxLines: maxLines, keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : null, decoration: InputDecoration(labelText: label), validator: (value) { if (required && (value == null || value.trim().isEmpty)) return 'Required'; if (number && value != null && value.trim().isNotEmpty && double.tryParse(value) == null) return 'Enter a number'; return null; }));
}

class _ItemDraft {
  final product = TextEditingController(); final quantity = TextEditingController(text: '1'); final unit = TextEditingController(); final purchaseRate = TextEditingController(); final sellingRate = TextEditingController(); final remarks = TextEditingController();
  _ItemDraft();
  _ItemDraft.fromModel(OrderItemModel item) { product.text = item.productName; quantity.text = item.quantity.toString(); unit.text = item.unit; purchaseRate.text = item.purchaseRate?.toString() ?? ''; sellingRate.text = item.sellingRate?.toString() ?? ''; remarks.text = item.remarks; }
  Map<String, dynamic> toJson() => {'product_name': product.text.trim(), 'quantity': double.parse(quantity.text), 'unit': unit.text.trim(), if (purchaseRate.text.trim().isNotEmpty) 'purchase_rate': double.parse(purchaseRate.text), if (sellingRate.text.trim().isNotEmpty) 'selling_rate': double.parse(sellingRate.text), 'remarks': remarks.text.trim()};
  void dispose() { for (final controller in [product, quantity, unit, purchaseRate, sellingRate, remarks]) controller.dispose(); }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primaryText));
}

class _PickerOption {
  const _PickerOption(this.id, this.name);
  final String id;
  final String name;
}

class _SearchPickerSheet extends StatefulWidget {
  const _SearchPickerSheet({required this.title, required this.options, required this.selectedId});
  final String title;
  final List<_PickerOption> options;
  final String? selectedId;
  @override State<_SearchPickerSheet> createState() => _SearchPickerSheetState();
}

class _SearchPickerSheetState extends State<_SearchPickerSheet> {
  final _search = TextEditingController();
  @override void dispose() { _search.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final filtered = widget.options.where((option) => option.name.toLowerCase().contains(query)).toList();
    return SafeArea(child: Container(height: MediaQuery.sizeOf(context).height * .75, padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Select ${widget.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryText))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
      const SizedBox(height: 8),
      TextField(controller: _search, autofocus: true, onChanged: (_) => setState(() {}), decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name')),
      const SizedBox(height: 10),
      Expanded(child: filtered.isEmpty ? const Center(child: Text('No matching records', style: TextStyle(color: AppColors.secondaryText))) : ListView.separated(itemCount: filtered.length, separatorBuilder: (_, _) => const Divider(height: 1), itemBuilder: (_, index) { final option = filtered[index]; final selected = option.id == widget.selectedId; return ListTile(contentPadding: EdgeInsets.zero, title: Text(option.name, style: const TextStyle(fontWeight: FontWeight.w600)), trailing: selected ? const Icon(Icons.check_circle, color: AppColors.primaryBlue) : null, onTap: () => Navigator.pop(context, option.id)); }))
    ])));
  }
}

String _formatDate(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
