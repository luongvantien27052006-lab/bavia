// lib/screens/address/address_form_screen.dart
//
// Form thêm/sửa địa chỉ. Nếu [existing] != null → chế độ sửa.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/address_model.dart';
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

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.recipientName ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _address = TextEditingController(text: e?.detailedAddress ?? '');
    _isDefault = e?.isDefault ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
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
      });
    } else {
      ok = await controller.create(AddressModel(
        id: '',
        recipientName: _name.text.trim(),
        phone: _phone.text.trim(),
        detailedAddress: _address.text.trim(),
        isDefault: _isDefault,
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

    return Scaffold(
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
                required: true, maxLines: 2),
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
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
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
