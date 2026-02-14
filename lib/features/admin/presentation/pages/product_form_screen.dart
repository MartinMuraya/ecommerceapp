import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qejani/core/constants/app_constants.dart';
import 'package:qejani/features/products/domain/models/product.dart';
import 'package:qejani/features/products/data/repositories/product_repository.dart';
import 'package:qejani/features/auth/presentation/providers/auth_providers.dart';
import 'package:qejani/features/core/services/storage_service.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  
  String _selectedCategory = AppConstants.categories.first;
  bool _isAvailable = true;
  bool _isLoading = false;
  List<String> _imageUrls = [];
  final List<XFile> _newImageFiles = [];

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    final product = await ref.read(productRepositoryProvider).getProduct(widget.productId!);
    if (product != null) {
      _titleController.text = product.title;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      _stockController.text = product.stock.toString();
      _imageUrls = product.images;
      _selectedCategory = product.category;
      _isAvailable = product.isAvailable;
    }
    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _newImageFiles.add(pickedFile);
      });
    }
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final storage = ref.read(storageServiceProvider);
        final uploadedUrls = await storage.uploadMultipleImages(_newImageFiles, 'products');
        final allImages = <String>[..._imageUrls, ...uploadedUrls];

        final user = ref.read(firebaseAuthProvider).currentUser;
        
        final product = Product(
          id: widget.productId ?? '',
          sellerId: user?.uid ?? 'admin',
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          currency: AppConstants.currency,
          category: _selectedCategory,
          images: allImages,
          stock: int.parse(_stockController.text),
          isAvailable: _isAvailable,
        );

        if (widget.productId == null) {
          await ref.read(productRepositoryProvider).addProduct(product);
        } else {
          await ref.read(productRepositoryProvider).updateProduct(product);
        }
        
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving product: $e')),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text(widget.productId == null ? 'Add Product' : 'Edit Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price (KES)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: AppConstants.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              const Text('Product Images', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._imageUrls.map((url) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Image.network(url, width: 100, height: 100, fit: BoxFit.cover),
                          Positioned(
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => setState(() => _imageUrls.remove(url)),
                            ),
                          ),
                        ],
                      ),
                    )),
                    ..._newImageFiles.map((file) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          FutureBuilder<Uint8List>(
                            future: file.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(snapshot.data!, width: 100, height: 100, fit: BoxFit.cover);
                              }
                              return Container(width: 100, height: 100, color: Colors.grey[300]);
                            },
                          ),
                          Positioned(
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () => setState(() => _newImageFiles.remove(file)),
                            ),
                          ),
                        ],
                      ),
                    )),
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add_a_photo, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('Is Available'),
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(widget.productId == null ? 'Create Product' : 'Update Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
