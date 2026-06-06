import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/portfolio_model.dart';
import '../providers/portfolio_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';

class AddEditPortfolioScreen extends ConsumerStatefulWidget {
  final PortfolioModel? portfolio;

  const AddEditPortfolioScreen({super.key, this.portfolio});

  @override
  ConsumerState<AddEditPortfolioScreen> createState() => _AddEditPortfolioScreenState();
}

class _AddEditPortfolioScreenState extends ConsumerState<AddEditPortfolioScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _toolsController;
  late String _imagePath;
  File? _selectedImage;
  late List<String> _selectedTags;
  late String? _selectedRank;
  bool _isUploading = false;

  final List<String> _availableTags = [
    'Cyberpunk', 'Chibi', 'Fantasy', 'Cute', 'Action', 'Romance', 'Background', 'Character',
  ];

  final List<String> _availableRanks = ['S', 'A', 'B', 'C'];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.portfolio?.title ?? '');
    _descriptionController = TextEditingController(text: widget.portfolio?.description ?? '');
    _toolsController = TextEditingController(text: widget.portfolio?.toolsUsed ?? '');
    _imagePath = widget.portfolio?.imagePath ?? '';
    _selectedTags = List.from(widget.portfolio?.tags ?? []);
    _selectedRank = widget.portfolio?.rank;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _toolsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePortfolio() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedTags.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih minimal 1 gaya anime!')),
        );
        return;
      }

      if (_selectedImage == null && widget.portfolio == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih gambar terlebih dahulu!')),
        );
        return;
      }

      setState(() => _isUploading = true);

      String finalImagePath = _imagePath;

      if (_selectedImage != null) {
        final uploadResult = await ApiService.uploadImage(_selectedImage!);
        if (uploadResult['success'] == true) {
          finalImagePath = uploadResult['image_path']; // relative path
        } else {
          setState(() => _isUploading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(uploadResult['message'] ?? 'Gagal upload gambar'), backgroundColor: AppColors.error),
          );
          return;
        }
      }

      final authState = ref.read(authProvider);
      final userId = authState.userId;

      final newPortfolio = PortfolioModel(
        id: widget.portfolio?.id ?? '',
        userId: userId,
        userName: authState.userName,
        userRole: authState.userRole,
        title: _titleController.text,
        description: _descriptionController.text,
        imagePath: finalImagePath,
        tags: _selectedTags,
        toolsUsed: _toolsController.text,
        createdAt: widget.portfolio?.createdAt ?? DateTime.now(),
        rank: _selectedRank,
      );

      if (widget.portfolio == null) {
        await ref.read(portfolioListProvider.notifier).addPortfolio(newPortfolio, userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Portofolio berhasil ditambahkan!')),
          );
        }
      } else {
        await ref.read(portfolioListProvider.notifier).updatePortfolio(newPortfolio);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Portofolio berhasil diupdate!')),
          );
        }
      }

      setState(() => _isUploading = false);
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.portfolio != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Portofolio' : 'Tambah Portofolio'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isUploading ? null : _savePortfolio,
            child: Text(
              'Simpan',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Picker
                  GestureDetector(
                    onTap: _showImagePickerDialog,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                              ),
                            )
                          : (widget.portfolio != null && widget.portfolio!.imagePath.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    widget.portfolio!.imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 200,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildImagePlaceholder();
                                    },
                                  ),
                                )
                              : _buildImagePlaceholder()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _showImagePickerDialog,
                      icon: const Icon(Icons.photo_camera, size: 18),
                      label: Text(
                        _selectedImage != null ? 'Ganti Gambar' : 'Pilih Gambar',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Judul
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Karya',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Judul tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Deskripsi
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Deskripsi tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Tools
                  TextFormField(
                    controller: _toolsController,
                    decoration: const InputDecoration(
                      labelText: 'Tools yang Digunakan',
                      hintText: 'Contoh: Clip Studio Paint, Procreate, Photoshop',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tags
                  const Text(
                    'Gaya Anime (pilih minimal 1)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _availableTags.map((tag) {
                      return FilterChip(
                        label: Text(tag),
                        selected: _selectedTags.contains(tag),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  if (_selectedTags.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Pilih minimal 1 gaya',
                          style: TextStyle(color: Colors.red[400], fontSize: 12),
                        ),
                      ),
                  const SizedBox(height: 16),
                  
                  // Rank
                  const Text(
                    'Tier Rank (Opsional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _availableRanks.map((rank) {
                      return ChoiceChip(
                        label: Text(rank),
                        selected: _selectedRank == rank,
                        onSelected: (selected) {
                          setState(() {
                            _selectedRank = selected ? rank : null;
                          });
                        },
                        selectedColor: _getRankColor(rank),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Tombol Simpan
                  ElevatedButton(
                    onPressed: _isUploading ? null : _savePortfolio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Simpan Portofolio'),
                  ),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Mengupload gambar...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.image, size: 50, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Tap untuk pilih gambar',
          style: TextStyle(color: Colors.grey[500], fontSize: 14),
        ),
      ],
    );
  }

  Color _getRankColor(String rank) {
    switch (rank) {
      case 'S':
        return Colors.amber;
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}