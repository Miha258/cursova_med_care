import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_service.dart';

// Екран оплати — вибір методу (картка / Apple Pay / Google Pay)
class PaymentScreen extends StatefulWidget {
  final String invoiceId;
  final double amount;
  final String description;
  final String patientName;

  const PaymentScreen({
    super.key,
    required this.invoiceId,
    required this.amount,
    required this.description,
    required this.patientName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

enum _PayMethod { card, applePay, googlePay }

class _PaymentScreenState extends State<PaymentScreen>
    with SingleTickerProviderStateMixin {
  _PayMethod _selected = _PayMethod.card;
  bool _processing = false;
  bool _done = false;

  // Card form
  final _cardNum = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();
  final _holder = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _checkAnim;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();
    _checkAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _checkScale = CurvedAnimation(parent: _checkAnim, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _cardNum.dispose();
    _expiry.dispose();
    _cvv.dispose();
    _holder.dispose();
    _checkAnim.dispose();
    super.dispose();
  }

  String get _methodKey => switch (_selected) {
    _PayMethod.card => 'card',
    _PayMethod.applePay => 'apple_pay',
    _PayMethod.googlePay => 'google_pay',
  };

  Future<void> _pay() async {
    if (_selected == _PayMethod.card) {
      if (!_formKey.currentState!.validate()) return;
    }
    setState(() => _processing = true);
    try {
      await ApiService.instance.patch(
        '/invoices/by-appointment/${widget.invoiceId}/pay',
        data: {'paymentMethod': _methodKey},
      );
      if (!mounted) return;
      setState(() { _processing = false; _done = true; });
      _checkAnim.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка оплати: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Оплата', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(widget.description,
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.amount.toStringAsFixed(2)} ₴',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_done) _buildSuccessCard() else ...[
                  _buildMethodSelector(),
                  const SizedBox(height: 16),
                  if (_selected == _PayMethod.card) _buildCardForm(),
                  if (_selected != _PayMethod.card) _buildWalletInfo(),
                  const SizedBox(height: 100),
                ],
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _done ? null : _buildPayButton(),
    );
  }

  Widget _buildMethodSelector() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('СПОСІБ ОПЛАТИ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1)),
        const SizedBox(height: 12),
        _methodTile(_PayMethod.card, Icons.credit_card_rounded, 'Банківська картка', 'Visa / Mastercard'),
        const SizedBox(height: 8),
        _methodTile(_PayMethod.applePay, Icons.apple, 'Apple Pay', 'Швидка оплата через Apple'),
        const SizedBox(height: 8),
        _methodTile(_PayMethod.googlePay, Icons.g_mobiledata_rounded, 'Google Pay', 'Швидка оплата через Google'),
      ],
    ),
  );

  Widget _methodTile(_PayMethod m, IconData icon, String label, String sub) {
    final active = _selected == m;
    return GestureDetector(
      onTap: () => setState(() => _selected = m),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.08) : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? AppColors.primary : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : const Color(0xFFE8ECF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: active ? Colors.white : AppColors.textSecondary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: active ? AppColors.primary : AppColors.text)),
                  Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: active ? AppColors.primary : AppColors.border, width: 2),
                color: active ? AppColors.primary : Colors.transparent,
              ),
              child: active ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    padding: const EdgeInsets.all(16),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ДАНІ КАРТКИ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 14),
          // Card preview
          _buildCardPreview(),
          const SizedBox(height: 16),
          // Card number
          _cardField(
            controller: _cardNum,
            hint: '0000 0000 0000 0000',
            label: 'Номер картки',
            icon: Icons.credit_card,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, _CardNumberFormatter()],
            validator: (v) => (v == null || v.replaceAll(' ', '').length < 16) ? 'Введіть 16 цифр' : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _cardField(
                controller: _expiry,
                hint: 'ММ/РР',
                label: 'Термін дії',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ExpiryFormatter()],
                validator: (v) => (v == null || v.length < 5) ? 'ММ/РР' : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _cardField(
                controller: _cvv,
                hint: '•••',
                label: 'CVV',
                icon: Icons.lock_outline,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                obscureText: true,
                validator: (v) => (v == null || v.length < 3) ? '3 цифри' : null,
              ),
            ),
          ]),
          const SizedBox(height: 12),
          _cardField(
            controller: _holder,
            hint: 'IVAN PETRENKO',
            label: 'Власник картки',
            icon: Icons.person_outline,
            inputFormatters: [UpperCaseTextFormatter()],
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Введіть ім\'я' : null,
          ),
        ],
      ),
    ),
  );

  Widget _buildCardPreview() {
    final num = _cardNum.text.isEmpty ? '•••• •••• •••• ••••' : _cardNum.text.padRight(19, '•');
    final exp = _expiry.text.isEmpty ? 'MM/RR' : _expiry.text;
    final name = _holder.text.isEmpty ? 'ВЛАСНИК КАРТКИ' : _holder.text.toUpperCase();

    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Icon(Icons.contactless, color: Colors.white54, size: 28),
            const Text('VISA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 2)),
          ]),
          const Spacer(),
          Text(num.length > 19 ? num.substring(0, 19) : num,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 3)),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(exp, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ],
      ),
    );
  }

  Widget _cardField({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        validator: validator,
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
          filled: true,
          fillColor: const Color(0xFFF7F8FA),
          labelStyle: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.danger)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      );

  Widget _buildWalletInfo() {
    final isApple = _selected == _PayMethod.applePay;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(isApple ? Icons.apple : Icons.g_mobiledata_rounded,
              size: 64, color: isApple ? Colors.black87 : const Color(0xFF4285F4)),
          const SizedBox(height: 16),
          Text(
            isApple ? 'Apple Pay' : 'Google Pay',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          Text(
            'Натисніть кнопку нижче для підтвердження\nоплати через ${isApple ? 'Apple Pay' : 'Google Pay'}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.success, size: 16),
                const SizedBox(width: 8),
                Text('Захищено ${isApple ? 'Face ID / Touch ID' : 'biometrics'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() => Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('До оплати', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text('${widget.amount.toStringAsFixed(2)} ₴',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.text)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _processing ? null : _pay,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _processing
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_selected == _PayMethod.card ? Icons.lock : Icons.touch_app, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _selected == _PayMethod.card ? 'Оплатити' : 'Підтвердити оплату',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 12, color: AppColors.textSecondary),
            SizedBox(width: 4),
            Text('Захищено SSL шифруванням', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ],
    ),
  );

  Widget _buildSuccessCard() => ScaleTransition(
    scale: _checkScale,
    child: Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('Оплата успішна!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.text)),
          const SizedBox(height: 8),
          Text(
            '${widget.amount.toStringAsFixed(2)} ₴',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(widget.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _receiptRow('Пацієнт', widget.patientName),
          _receiptRow('Метод оплати', switch (_selected) {
            _PayMethod.card => '💳 Банківська картка',
            _PayMethod.applePay => ' Apple Pay',
            _PayMethod.googlePay => '🟦 Google Pay',
          }),
          _receiptRow('Статус', '✅ Оплачено'),
          _receiptRow('Дата', _formatNow()),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Готово', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _receiptRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
      ],
    ),
  );

  String _formatNow() {
    final n = DateTime.now();
    return '${n.day.toString().padLeft(2, '0')}.${n.month.toString().padLeft(2, '0')}.${n.year} ${n.hour.toString().padLeft(2, '0')}:${n.minute.toString().padLeft(2, '0')}';
  }
}

// ─── Formatters ───────────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return newValue.copyWith(text: str, selection: TextSelection.collapsed(offset: str.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    if (digits.length <= 2) return newValue.copyWith(text: digits);
    final str = '${digits.substring(0, 2)}/${digits.substring(2, digits.length.clamp(0, 4))}';
    return newValue.copyWith(text: str, selection: TextSelection.collapsed(offset: str.length));
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue _, TextEditingValue n) =>
      n.copyWith(text: n.text.toUpperCase());
}
