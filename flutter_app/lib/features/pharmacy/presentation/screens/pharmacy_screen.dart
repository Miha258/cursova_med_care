import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';

class PharmacyScreen extends StatefulWidget {
  final void Function(int) onNavigate;
  const PharmacyScreen({super.key, required this.onNavigate});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final _api = ApiService.instance;
  final _searchCtrl = TextEditingController();

  List<dynamic> _all = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await _api.get('/medications');
      final list = r.data as List;
      setState(() {
        _all = list;
        _filtered = list;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _search(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _all
          : _all.where((m) => (m['name'] as String).toLowerCase().contains(lower)).toList();
    });
  }

  Future<void> _delete(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Видалити препарат?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('$name буде видалено з каталогу.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, foregroundColor: Colors.white),
            child: const Text('Видалити'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.delete('/medications/$id');
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Препарати', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Оновити', onPressed: _load),
          IconButton(icon: const Icon(Icons.add), tooltip: 'Додати', onPressed: () => _showAddSheet()),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _search,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Пошук препарату...',
                hintStyle: const TextStyle(color: Colors.white60),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: const TextStyle(color: AppColors.danger)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _load, child: const Text('Повторити')),
                  ],
                ))
              : _filtered.isEmpty
                  ? const Center(child: Text('Препаратів не знайдено'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _medCard(_filtered[i]),
                      ),
                    ),
      bottomNavigationBar: MedCareBottomNav(currentIndex: 3, onTap: widget.onNavigate),
    );
  }

  Widget _medCard(dynamic m) {
    final qty = (m['quantity'] ?? 0) as int;
    final minQty = (m['minQuantity'] ?? 0) as int;
    final isLow = qty <= minQty;
    final price = double.tryParse(m['price']?.toString() ?? '0') ?? 0.0;
    final expiry = (m['expiryDate'] ?? '') as String;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: isLow ? Border.all(color: AppColors.danger.withValues(alpha: 0.4)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isLow ? AppColors.danger.withValues(alpha: 0.1) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.medication_outlined, color: isLow ? AppColors.danger : AppColors.success, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(m['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text))),
                    if (isLow)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                        child: const Text('Мало', style: TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _chip('${m['unit'] ?? ''}', AppColors.textSecondary),
                    const SizedBox(width: 8),
                    _chip('$qty шт.', isLow ? AppColors.danger : AppColors.textSecondary),
                    const SizedBox(width: 8),
                    _chip('${price.toStringAsFixed(0)} грн', AppColors.primary),
                    if (expiry.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _chip('до ${expiry.substring(0, 7)}', AppColors.textSecondary),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
            onPressed: () => _delete(m['id'] as String, m['name'] as String),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600));

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddMedSheet(onSaved: _load),
    );
  }
}

class _AddMedSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddMedSheet({required this.onSaved});

  @override
  State<_AddMedSheet> createState() => _AddMedSheetState();
}

class _AddMedSheetState extends State<_AddMedSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _minQtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  String _unit = 'таб.';
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _qtyCtrl.dispose(); _minQtyCtrl.dispose();
    _priceCtrl.dispose(); _expiryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService.instance.post('/medications', data: {
        'name': _nameCtrl.text.trim(),
        'quantity': int.tryParse(_qtyCtrl.text) ?? 0,
        'minQuantity': int.tryParse(_minQtyCtrl.text) ?? 10,
        'unit': _unit,
        'price': double.tryParse(_priceCtrl.text) ?? 0,
        if (_expiryCtrl.text.isNotEmpty) 'expiryDate': _expiryCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e'), backgroundColor: AppColors.danger));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Center(child: Text('Новий препарат', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              const SizedBox(height: 20),
              _field(_nameCtrl, 'Назва препарату', required: true),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field(_qtyCtrl, 'Кількість', keyboard: TextInputType.number, required: true)),
                const SizedBox(width: 12),
                Expanded(child: _field(_minQtyCtrl, 'Мін. залишок', keyboard: TextInputType.number)),
              ]),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _unit,
                decoration: _dec('Одиниця'),
                items: ['таб.', 'капс.', 'амп.', 'фл.', 'мл', 'г']
                    .map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setState(() => _unit = v ?? 'таб.'),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _field(_priceCtrl, 'Ціна (грн)', keyboard: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _field(_expiryCtrl, 'Термін (РРРР-ММ-ДД)')),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Зберегти', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {bool required = false, TextInputType? keyboard}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: _dec(required ? '$label *' : label),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? "Обов'язкове поле" : null : null,
      );

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  );
}
