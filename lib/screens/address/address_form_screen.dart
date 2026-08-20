// ============================================================
//  FLUTTER
//  lib/screens/address/address_form_screen.dart
//  >> CHEP DE (nut Ghim vi tri)
// ============================================================

// lib/screens/address/address_form_screen.dart
//
// Form thêm/sửa địa chỉ. Nếu [existing] != null → chế độ sửa.

import 'dart:async';

import 'package:flutter/material.dart';
import '../../widgets/glass_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/network/api_client.dart';
import '../../models/address_model.dart';
import '../../services/location_service.dart';
import '../../providers/address_provider.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  final AddressModel? existing;
  const AddressFormScreen({super.key, this.existing});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late bool _isDefault;
  double? _lat;
  double? _lng;
  bool _locating = false;
  final List<Map<String, String>> _suggestions = [];
  Timer? _debounce;
  bool _searching = false;

  bool get _isEdit => widget.existing != null;
  bool get _hasCoords => _lat != null && _lng != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.recipientName ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _address = TextEditingController(text: e?.detailedAddress ?? '');
    _isDefault = e?.isDefault ?? false;
    _lat = e?.latitude;
    _lng = e?.longitude;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final controller = ref.read(addressControllerProvider.notifier);
    bool ok;
    if (_isEdit) {
      ok = await controller.update(widget.existing!.id, {
        'receiverName': _name.text.trim(),
        'receiverPhone': _phone.text.trim(),
        'detailedAddress': _address.text.trim(),
        'isDefault': _isDefault,
        if (_lat != null) 'latitude': _lat,
        if (_lng != null) 'longitude': _lng,
      });
    } else {
      ok = await controller.create(AddressModel(
        id: '',
        recipientName: _name.text.trim(),
        phone: _phone.text.trim(),
        detailedAddress: _address.text.trim(),
        isDefault: _isDefault,
        latitude: _lat,
        longitude: _lng,
      ));
    }

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      final err = ref.read(addressControllerProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.hasError ? '${err.error}' : 'Lưu thất bại'),
          backgroundColor: AppColors.delivery,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(addressControllerProvider).isLoading;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        
      appBar: AppBar(
        title: Text(_isEdit ? 'Sửa địa chỉ' : 'Thêm địa chỉ',
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(_name, 'Tên người nhận', Icons.person_outline_rounded,
                required: true),
            const SizedBox(height: 14),
            _field(_phone, 'Số điện thoại', Icons.phone_outlined,
                required: true, keyboard: TextInputType.phone),
            const SizedBox(height: 14),
            _field(_address, 'Địa chỉ đầy đủ', Icons.location_on_outlined,
                required: true, maxLines: 2, onChanged: _onAddressChanged),
            _suggestionList(),
            const SizedBox(height: 6),
            _gpsButton(),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              title: const Text('Đặt làm địa chỉ mặc định'),
              activeColor: AppColors.coffee,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: saving ? null : _save,
            child: saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : Text(_isEdit ? 'Lưu thay đổi' : 'Thêm địa chỉ'),
          ),
        ),
      ),
    ));
  }

  /// Nút TUỲ CHỌN: lấy vị trí hiện tại (GPS) để tính phí ship chính xác hơn.
  /// Không bắt buộc — nếu bỏ qua, hệ thống tự tính phí theo địa chỉ đã nhập.
  Widget _gpsButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _locating ? null : _pickLocation,
        style: TextButton.styleFrom(padding: EdgeInsets.zero),
        icon: _locating
            ? const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(
                _hasCoords
                    ? Icons.check_circle_rounded
                    : Icons.my_location_rounded,
                size: 18,
                color: _hasCoords ? AppColors.coffee : AppColors.textMuted,
              ),
        label: Text(
          _hasCoords
              ? 'Đã lấy vị trí hiện tại (phí ship chính xác)'
              : 'Dùng vị trí hiện tại để tính phí chính xác hơn',
          style: TextStyle(
            fontSize: 13,
            color: _hasCoords ? AppColors.coffee : AppColors.textMuted,
          ),
        ),
      ),
    );
  }


  // ── Gợi ý địa chỉ (Goong autocomplete) ──
  void _onAddressChanged(String text) {
    _debounce?.cancel();
    // Khách gõ lại -> toạ độ cũ không còn đúng, xoá để tính lại theo địa chỉ mới.
    _lat = null;
    _lng = null;
    if (text.trim().length < 2) {
      setState(() => _suggestions.clear());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350),
        () => _searchAddress(text.trim()));
  }

  Future<void> _searchAddress(String input) async {
    setState(() => _searching = true);
    try {
      final data = await ApiClient.I.get('/goong/autocomplete',
          query: {'input': input}, skipAuth: true);
      final preds = (data is Map && data['predictions'] is List)
          ? (data['predictions'] as List)
          : const [];
      if (!mounted) return;
      setState(() {
        _suggestions
          ..clear()
          ..addAll(preds.map((p) => <String, String>{
                'description': '${p['description'] ?? ''}',
                'placeId': '${p['placeId'] ?? ''}',
              }));
      });
    } catch (_) {
      // im lặng — vẫn cho nhập tay
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _pickSuggestion(Map<String, String> s) async {
    FocusScope.of(context).unfocus();
    _address.text = s['description'] ?? _address.text;
    setState(() => _suggestions.clear());
    final pid = s['placeId'] ?? '';
    if (pid.isEmpty) return;
    try {
      final data = await ApiClient.I.get('/goong/place',
          query: {'placeId': pid}, skipAuth: true);
      if (data is Map && mounted) {
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();
        final addr = '${data['address'] ?? ''}';
        setState(() {
          _lat = lat;
          _lng = lng;
          if (addr.isNotEmpty) _address.text = addr;
        });
      }
    } catch (_) {}
  }

  Widget _suggestionList() {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppColors.dark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: _suggestions.take(5).map((s) {
          return ListTile(
            dense: true,
            leading:
                const Icon(Icons.place_outlined, size: 18, color: AppColors.coffee),
            title: Text(s['description'] ?? '',
                style: const TextStyle(fontSize: 13)),
            onTap: () => _pickSuggestion(s),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _pickLocation() async {
    setState(() => _locating = true);
    final res = await LocationService.instance.getCurrent();
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (res != null) {
        _lat = res.latitude;
        _lng = res.longitude;
        _suggestions.clear();
      }
    });
    if (res != null) {
      // Lấy địa chỉ chữ từ toạ độ GPS để ghi vào ô (khách xem/sửa được).
      try {
        final data = await ApiClient.I.get('/goong/reverse',
            query: {'lat': '${res.latitude}', 'lng': '${res.longitude}'},
            skipAuth: true);
        if (data is Map && mounted) {
          final addr = '${data['address'] ?? ''}';
          if (addr.isNotEmpty) _address.text = addr;
        }
      } catch (_) {}
    }
    if (res == null) {
      final svc = LocationService.instance;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(svc.lastErrorMessage),
          backgroundColor: AppColors.delivery,
          action: svc.lastError == LocationError.deniedForever
              ? SnackBarAction(
                  label: 'Cài đặt',
                  textColor: Colors.white,
                  onPressed: svc.openSettings,
                )
              : null,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lấy vị trí hiện tại')),
      );
    }
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        alignLabelWithHint: true,
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
              ? 'Vui lòng nhập $label'
              : null
          : null,
    );
  }
}