import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/appointment_service.dart';
import '../services/shop_service.dart';
import '../utils/currency.dart';
import '../utils/product_colors.dart';
import '../widgets/product_image.dart';

const _bg = Color(0xFFF2F2EE);
const _white = Colors.white;
const _dark = Color(0xFF2A2A2A);
const _grey = Color(0xFF8B8B8B);
const _gold = Color(0xFFC4A464);

class ItemDetailsScreen extends StatefulWidget {
  final Product product;
  const ItemDetailsScreen({super.key, required this.product});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  int _qty = 1;
  ProductColor? _selectedColor;

  Product get _product => widget.product;
  double get _total => _product.value * _qty;
  bool get _hasColors => _product.colors.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _selectedColor = _product.colors.isNotEmpty ? _product.colors.first : null;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Plus Jakarta Sans')),
        backgroundColor: _dark,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  Future<void> _addToCart() async {
    if (_product.isOutOfStock) {
      _snack('${_product.name} is currently out of stock');
      return;
    }
    if (_hasColors && _selectedColor == null) {
      _snack('Please select a colour');
      return;
    }
    await ShopService.instance.addToCart(
      _product,
      qty: _qty,
      color: _selectedColor,
    );
    if (!mounted) return;
    final colorNote = _selectedColor != null ? ' (${_selectedColor!.name})' : '';
    _snack('Added $_qty × ${_product.name}$colorNote to cart');
  }

  Future<void> _bookAppointment() async {
    // Show appointment booking form
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AppointmentBookingForm(product: _product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with overlaid back + favourite + cart
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16, MediaQuery.of(context).padding.top + 12, 16, 0,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.48,
                            width: double.infinity,
                            child: ProductImage(
                              imageUrl: product.imageUrl,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _circleBtn(
                                icon: Icons.arrow_back,
                                onTap: () => Navigator.of(context).maybePop(),
                              ),
                            ],
                          ),
                        ),
                        if (product.badge != null && product.badge!.isNotEmpty)
                          Positioned(
                            bottom: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: _gold,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                product.badge!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _white,
                                  fontFamily: 'Plus Jakarta Sans',
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Name + quantity stepper
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: _dark,
                                  fontFamily: 'Plus Jakarta Sans',
                                ),
                              ),
                              if (product.desc.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  product.desc,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _grey,
                                    fontFamily: 'Plus Jakarta Sans',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _QtyStepper(
                          qty: _qty,
                          onIncrement: () => setState(() => _qty++),
                          onDecrement: () =>
                              setState(() => _qty > 1 ? _qty-- : _qty),
                        ),
                      ],
                    ),
                  ),

                  // Price per unit
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                    child: Text(
                      '${formatUgx(product.value)} / ${product.unit}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _gold,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                  ),

                  // Per-piece dimensions / coverage (when the admin set them)
                  if (product.hasDimensions)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Row(
                        children: [
                          const Icon(Icons.straighten_rounded,
                              size: 16, color: _grey),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              product.areaPerUnitSqm != null
                                  ? '${product.dimensionsLabel} · ${product.areaPerUnitSqm} m²/piece'
                                  : product.dimensionsLabel,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: _grey,
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Description
                  if (product.about.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Text(
                        product.about,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: _grey,
                          fontFamily: 'Plus Jakarta Sans',
                          height: 1.5,
                        ),
                      ),
                    ),

                  if (_hasColors) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Text(
                        'COLOUR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: _grey,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: product.colors.map((c) {
                          final active = _selectedColor?.name == c.name;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = c),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: _white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: active ? _gold : const Color(0xFFE4E4DE),
                                  width: active ? 2 : 1.5,
                                ),
                                boxShadow: active
                                    ? [
                                        BoxShadow(
                                          color: _gold.withOpacity(0.25),
                                          blurRadius: 0,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: _parseColor(c.hex),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.black.withOpacity(0.12),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    c.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _dark,
                                      fontFamily: 'Plus Jakarta Sans',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool dark = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: dark ? _dark : _white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: dark ? _white : _dark, size: 20),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20, 18, 20, 18 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Total price + slide to visualise
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Price',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _grey,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatUgx(_total),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _dark,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Order + Book Appointment (wired in the Orders / Appointments phases)
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _addToCart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Center(
                      child: Text(
                        'Add to Cart',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _white,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: _bookAppointment,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: _white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: _dark, width: 1.5),
                    ),
                    child: const Center(
                      child: Text(
                        'Book Appointment',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _dark,
                          fontFamily: 'Plus Jakarta Sans',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _parseColor(String hex) {
  var h = hex.trim();
  if (!h.startsWith('#')) h = '#$h';
  if (h.length == 7) {
    final v = int.tryParse(h.substring(1), radix: 16);
    if (v != null) return Color(0xFF000000 | v);
  }
  return const Color(0xFF888888);
}

class _QtyStepper extends StatelessWidget {
  final int qty;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QtyStepper({
    required this.qty,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepBtn(Icons.remove, onDecrement),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              '$qty',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _dark,
                fontFamily: 'Plus Jakarta Sans',
              ),
            ),
          ),
          _stepBtn(Icons.add, onIncrement),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(color: _bg, shape: BoxShape.circle),
        child: Icon(icon, size: 17, color: _dark),
      ),
    );
  }
}

/// Slide-to-confirm button. Drag the thumb to the right to trigger [onComplete].
class _SlideToAction extends StatefulWidget {
  final String label;
  final VoidCallback onComplete;

  const _SlideToAction({required this.label, required this.onComplete});

  @override
  State<_SlideToAction> createState() => _SlideToActionState();
}

class _SlideToActionState extends State<_SlideToAction> {
  double _dragX = 0;
  static const double _height = 58;
  static const double _thumb = 50;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxX = constraints.maxWidth - _thumb - 8;
        return Container(
          height: _height,
          decoration: BoxDecoration(
            color: _dark,
            borderRadius: BorderRadius.circular(_height / 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.only(left: _thumb * 0.6),
                child: Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _white,
                    fontFamily: 'Plus Jakarta Sans',
                  ),
                ),
              ),
              Positioned(
                left: 4 + _dragX,
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) {
                    setState(() {
                      _dragX = (_dragX + d.delta.dx).clamp(0, maxX);
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    if (_dragX >= maxX * 0.85) {
                      widget.onComplete();
                    }
                    setState(() => _dragX = 0);
                  },
                  child: Container(
                    width: _thumb,
                    height: _thumb,
                    decoration: const BoxDecoration(
                      color: _gold,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: _white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


class _AppointmentBookingForm extends StatefulWidget {
  final Product product;
  const _AppointmentBookingForm({required this.product});

  @override
  State<_AppointmentBookingForm> createState() => _AppointmentBookingFormState();
}

class _AppointmentBookingFormState extends State<_AppointmentBookingForm> {
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date != null) {
      _dateCtrl.text = '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time != null && mounted) {
      _timeCtrl.text = time.format(context);
    }
  }

  Future<void> _submit() async {
    if (_dateCtrl.text.trim().isEmpty || _timeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a date and time')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await AppointmentService.instance.requestAppointment(
        aboutProduct: widget.product,
        date: _dateCtrl.text.trim(),
        time: _timeCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment request sent!')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not book appointment')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 32, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Book Appointment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: _dark, fontFamily: 'Plus Jakarta Sans')),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(color: _white, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 20, color: _dark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Booking for ${widget.product.name}',
                style: const TextStyle(fontSize: 14, color: _grey, fontFamily: 'Plus Jakarta Sans'),
              ),
              const SizedBox(height: 24),
              _field('Preferred Date', _dateCtrl, Icons.calendar_today_outlined,
                  hint: 'e.g. 25 July 2026', readOnly: true, onTap: _pickDate, required: true),
              const SizedBox(height: 16),
              _field('Preferred Time', _timeCtrl, Icons.access_time_outlined,
                  hint: 'e.g. 10:00 AM', readOnly: true, onTap: _pickTime, required: true),
              const SizedBox(height: 16),
              _field('Notes', _noteCtrl, Icons.notes_outlined,
                  hint: 'Any specific requirements or questions? (optional)', maxLines: 3),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _busy ? null : _submit,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(color: _dark, borderRadius: BorderRadius.circular(28)),
                  alignment: Alignment.center,
                  child: _busy
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(_white)))
                      : const Text('Confirm Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _white, fontFamily: 'Plus Jakarta Sans')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {String hint = '', bool required = false, bool readOnly = false, VoidCallback? onTap, TextInputType keyboard = TextInputType.text, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${label.toUpperCase()}${required ? ' *' : ''}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _grey, fontFamily: 'Plus Jakarta Sans', letterSpacing: 0.8)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(
              children: [
                Icon(icon, size: 20, color: _grey),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    readOnly: readOnly,
                    keyboardType: keyboard,
                    maxLines: maxLines,
                    onTap: onTap,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _dark, fontFamily: 'Plus Jakarta Sans'),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(color: Color(0xFFB8B8B8), fontSize: 14, fontFamily: 'Plus Jakarta Sans'),
                      border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
