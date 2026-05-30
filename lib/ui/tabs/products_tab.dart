import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/salary_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product.dart';

class ProductsTab extends StatelessWidget {
  const ProductsTab({super.key});

  void _openAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AddProductDialog(),
    );
  }

  void _openEditPriceDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (_) => _EditPriceDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salaryProv = Provider.of<SalaryProvider>(context);
    final authProv = Provider.of<AuthProvider>(context);
    final products = salaryProv.products;
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Không có sản phẩm nào',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final prod = products[index];
                final isActive = prod.active;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isActive ? Colors.teal.shade50 : Colors.grey.shade200,
                      foregroundColor: isActive ? Colors.teal.shade800 : Colors.grey.shade600,
                      child: const Icon(Icons.inventory_2),
                    ),
                    title: Row(
                      children: [
                        Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Tạm ngưng', style: TextStyle(fontSize: 9, color: Colors.grey)),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Đơn vị tính: ${prod.unit}'),
                        const SizedBox(height: 2),
                        Text(
                          'Đơn giá mặc định: ${currencyFormat.format(prod.defaultPrice)}',
                          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    trailing: authProv.isAdmin
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                tooltip: 'Sửa giá',
                                onPressed: () => _openEditPriceDialog(context, prod),
                              ),
                              IconButton(
                                icon: Icon(
                                  isActive ? Icons.visibility : Icons.visibility_off,
                                  color: isActive ? Colors.purple : Colors.grey,
                                ),
                                tooltip: isActive ? 'Ngưng dùng' : 'Kích hoạt',
                                onPressed: () {
                                  salaryProv.toggleProductActive(prod);
                                },
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              },
            ),
      floatingActionButton: authProv.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _openAddProductDialog(context),
              label: const Text('Thêm sản phẩm'),
              icon: const Icon(Icons.add_box),
            )
          : null,
    );
  }
}

class _AddProductDialog extends StatefulWidget {
  const _AddProductDialog();

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _unitController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final salaryProv = Provider.of<SalaryProvider>(context, listen: false);
      await salaryProv.addProduct(
        _nameController.text.trim(),
        _unitController.text.trim(),
        int.parse(_priceController.text),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã thêm sản phẩm thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm Sản Phẩm Mới'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tên sản phẩm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'VD: Giấy cuộn'),
              validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
            ),
            const SizedBox(height: 12),
            const Text('Đơn vị tính', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _unitController,
              decoration: const InputDecoration(hintText: 'VD: Tấn, Bao, Thùng'),
              validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập đơn vị tính' : null,
            ),
            const SizedBox(height: 12),
            const Text('Đơn giá mặc định (đ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'VD: 900000'),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Vui lòng nhập đơn giá';
                if (int.tryParse(val) == null) return 'Đơn giá phải là số nguyên';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Thêm'),
        ),
      ],
    );
  }
}

class _EditPriceDialog extends StatefulWidget {
  final Product product;
  const _EditPriceDialog({required this.product});

  @override
  State<_EditPriceDialog> createState() => _EditPriceDialogState();
}

class _EditPriceDialogState extends State<_EditPriceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _priceController.text = widget.product.defaultPrice.toString();
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final salaryProv = Provider.of<SalaryProvider>(context, listen: false);
      await salaryProv.updateProductPrice(widget.product, int.parse(_priceController.text));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã cập nhật đơn giá thành công!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sửa Đơn Giá: ${widget.product.name}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Đơn giá mới (đ)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'VD: 950000'),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Vui lòng nhập đơn giá';
                if (int.tryParse(val) == null) return 'Đơn giá phải là số nguyên';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(minimumSize: const Size(100, 44)),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Text('Cập nhật'),
        ),
      ],
    );
  }
}
