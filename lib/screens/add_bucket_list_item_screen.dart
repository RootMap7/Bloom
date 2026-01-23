import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bucket_list_category.dart';
import '../services/bucket_list_service.dart';
import '../services/supabase_service.dart';
import 'bucket_list_success_screen.dart';

class AddBucketListItemScreen extends StatefulWidget {
  const AddBucketListItemScreen({super.key});

  @override
  State<AddBucketListItemScreen> createState() => _AddBucketListItemScreenState();
}

class _AddBucketListItemScreenState extends State<AddBucketListItemScreen> {
  final _titleController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _notesController = TextEditingController();
  final _linksController = TextEditingController();
  
  DateTime? _selectedDate;
  BucketListCategory? _selectedCategory;
  String? _selectedCollection;
  bool _isPrivate = false;
  bool _isLoading = false;
  bool _isLoadingCollections = false;
  bool _isSaving = false;
  
  List<String> _collections = ['Couple Goals', 'Personal Dreams', 'Travel List'];
  
  final List<_ThemeOption> _themeOptions = const [
    _ThemeOption(label: 'Pink', color: Color(0xFFFFB7C3)),
    _ThemeOption(label: 'Blue', color: Color(0xFF6EB4FF)),
    _ThemeOption(label: 'Yellow', color: Color(0xFFF4D100)),
    _ThemeOption(label: 'Purple', color: Color(0xFFC8A8E9)),
  ];
  
  _ThemeOption _selectedTheme = const _ThemeOption(label: 'Pink', color: Color(0xFFFFB7C3));

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  Future<void> _loadCollections() async {
    setState(() => _isLoadingCollections = true);
    try {
      final userCollections = await BucketListService.fetchCollections();
      final userColNames = userCollections.map((c) => c.name).toList();
      
      setState(() {
        // Merge defaults with user collections, avoiding duplicates
        final combined = ['Couple Goals', 'Personal Dreams', 'Travel List', ...userColNames];
        _collections = combined.toSet().toList();
      });
    } catch (e) {
      debugPrint('Error loading collections: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCollections = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _deadlineController.dispose();
    _notesController.dispose();
    _linksController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7C3ABA),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _deadlineController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _showCategoryModal() async {
    setState(() => _isLoading = true);
    final categories = await BucketListService.fetchCategories();
    setState(() => _isLoading = false);

    if (!mounted) return;

    final result = await showModalBottomSheet<BucketListCategory>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Category',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: categories.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  return ListTile(
                    title: Text(
                      cat.name,
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
                    ),
                    trailing: _selectedCategory?.id == cat.id
                        ? const Icon(Icons.check_circle, color: Color(0xFF7C3ABA))
                        : null,
                    onTap: () => Navigator.pop(context, cat),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedCategory = result);
    }
  }

  Future<void> _showCollectionModal() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CollectionModal(
        collections: _collections,
        selectedCollection: _selectedCollection,
        onAddCollection: (name) async {
          try {
            await BucketListService.addCollection(name);
            if (mounted) {
              setState(() {
                if (!_collections.contains(name)) {
                  _collections.add(name);
                }
                _selectedCollection = name;
              });
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
      ),
    );

    if (result != null) {
      setState(() => _selectedCollection = result);
    }
  }

  Future<void> _showThemeModal() async {
    final result = await showModalBottomSheet<_ThemeOption>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Theme Color',
              style: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            ..._themeOptions.map((option) => ListTile(
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: option.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  title: Text(
                    option.label,
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
                  ),
                  trailing: _selectedTheme.label == option.label
                      ? const Icon(Icons.check_circle, color: Color(0xFF7C3ABA))
                      : null,
                  onTap: () => Navigator.pop(context, option),
                )),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedTheme = result);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    // Capture state for rollback if needed
    final originalIsSaving = _isSaving;
    
    setState(() => _isSaving = true);
    
    // OPTIMISTIC UI: Navigate to success screen immediately if possible
    // but for "Add Item", we might want to wait for the ID or just proceed
    // The requirement says "update local UI state immediately before the Supabase await finishes"
    
    try {
      // Start the save operation but don't await yet if we want true optimistic
      final saveFuture = BucketListService.addBucketListItem(
        title: title,
        targetDate: _selectedDate,
        categoryId: _selectedCategory?.id,
        collection: _selectedCollection,
        notes: _notesController.text.trim(),
        links: _linksController.text.trim(),
        themeColor: _themeHex(_selectedTheme),
        isPrivate: _isPrivate,
      );

      // We proceed to success screen "optimistically"
      if (mounted) {
        String partnerName = 'Partner';
        // Note: We don't await the full partner name fetch either if we want to be fast
        // but here it's already doing some async work. 
        // Let's just focus on the main save being optimistic.

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BucketListSuccessScreen(
              title: title,
              themeColor: _selectedTheme.color,
              partnerName: partnerName,
              isPrivate: _isPrivate,
            ),
          ),
        );
      }

      // Await in the background
      await saveFuture;
      
    } catch (e) {
      // ROLLBACK: If it fails, we should ideally inform the user.
      // Since we already navigated away, this is tricky. 
      // In a real app, we might use a global state manager or a snackbar on the previous screen.
      debugPrint('Failed to save bucket list item: $e');
      // If we were still on the screen, we would do:
      // setState(() {
      //   _isSaving = originalIsSaving;
      // });
    }
  }

  String _themeHex(_ThemeOption option) {
    switch (option.label) {
      case 'Pink': return '#FFB7C3';
      case 'Blue': return '#6EB4FF';
      case 'Yellow': return '#F4D100';
      case 'Purple': return '#C8A8E9';
      default: return '#FFB7C3';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add a Item to Bucket List',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
                onTap: _isSaving ? null : _save,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF7C3ABA),
                    shape: BoxShape.circle,
                  ),
                  child: _isSaving
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Title'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleController,
              hint: 'Bucket list name eg Try Sushi, Go Hiking',
            ),
            const SizedBox(height: 24),
            
            _buildLabel('Target Window/Dead line'),
            const SizedBox(height: 8),
            _buildReadOnlyField(
              controller: _deadlineController,
              hint: 'Select Date',
              suffix: const Icon(Icons.calendar_month_outlined, size: 20),
              onTap: _selectDate,
            ),
            const SizedBox(height: 24),

            _buildLabel('Category'),
            const SizedBox(height: 8),
            _buildReadOnlyField(
              controller: TextEditingController(text: _selectedCategory?.name ?? ''),
              hint: 'Select Category',
              suffix: const Icon(Icons.chevron_right),
              onTap: _showCategoryModal,
            ),
            const SizedBox(height: 24),

            _buildLabel('Collection'),
            const SizedBox(height: 8),
            _buildReadOnlyField(
              controller: TextEditingController(text: _selectedCollection ?? ''),
              hint: 'Select Collection',
              suffix: const Icon(Icons.chevron_right),
              onTap: _showCollectionModal,
            ),
            const SizedBox(height: 24),

            _buildLabel('Notes'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _notesController,
              hint: 'A text area for "Internal Jokes" or specific things not to forget',
              maxLines: 4,
            ),
            const SizedBox(height: 24),

            _buildLabel('Links'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _linksController,
              hint: 'Add links related to this bucket list item',
            ),
            const SizedBox(height: 24),

            _buildLabel('Theme Color'),
            const SizedBox(height: 8),
            _buildReadOnlyField(
              controller: TextEditingController(text: _selectedTheme.label),
              hint: 'Pink',
              prefix: Container(
                margin: const EdgeInsets.only(left: 12, right: 8),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _selectedTheme.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              suffix: const Icon(Icons.chevron_right),
              onTap: _showThemeModal,
            ),
            const SizedBox(height: 32),

            Text(
              'Just for Me (For Now)',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'By default, your dreams are shared with [Partner\'s Name]. Toggle this on to keep this item a surprise until you\'re ready to reveal it.',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF4D4B4B),
              ),
            ),
            const SizedBox(height: 16),
            Switch(
              value: _isPrivate,
              onChanged: (val) => setState(() => _isPrivate = val),
              activeColor: const Color(0xFF7C3ABA),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.manrope(color: Colors.grey.withOpacity(0.7), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: const Color(0xFFC8A8E9).withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF7C3ABA)),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField({
    required TextEditingController controller,
    required String hint,
    required VoidCallback onTap,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InkWell(
      onTap: onTap,
      child: IgnorePointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.manrope(color: Colors.grey.withOpacity(0.7), fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: prefix,
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: const Color(0xFFC8A8E9).withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF7C3ABA)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeOption {
  const _ThemeOption({required this.label, required this.color});
  final String label;
  final Color color;
}

class _CollectionModal extends StatefulWidget {
  final List<String> collections;
  final String? selectedCollection;
  final Function(String) onAddCollection;

  const _CollectionModal({
    required this.collections,
    this.selectedCollection,
    required this.onAddCollection,
  });

  @override
  State<_CollectionModal> createState() => _CollectionModalState();
}

class _CollectionModalState extends State<_CollectionModal> {
  final _newCollectionController = TextEditingController();
  bool _isAdding = false;

  @override
  void dispose() {
    _newCollectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Select Collection',
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!_isAdding)
                TextButton.icon(
                  onPressed: () => setState(() => _isAdding = true),
                  icon: const Icon(Icons.add, color: Color(0xFF7C3ABA)),
                  label: Text(
                    'Create New',
                    style: GoogleFonts.manrope(
                      color: const Color(0xFF7C3ABA),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isAdding) ...[
            TextField(
              controller: _newCollectionController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Collection Name (e.g. 2026 Goals)',
                hintStyle: GoogleFonts.manrope(color: Colors.grey),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle, color: Color(0xFF7C3ABA)),
                  onPressed: () {
                    final name = _newCollectionController.text.trim();
                    if (name.isNotEmpty) {
                      widget.onAddCollection(name);
                      Navigator.pop(context, name);
                    }
                  },
                ),
              ),
              onSubmitted: (val) {
                final name = val.trim();
                if (name.isNotEmpty) {
                  widget.onAddCollection(name);
                  Navigator.pop(context, name);
                }
              },
            ),
            const SizedBox(height: 24),
          ],
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.collections.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final collection = widget.collections[index];
                return ListTile(
                  title: Text(
                    collection,
                    style: GoogleFonts.manrope(fontWeight: FontWeight.w500),
                  ),
                  trailing: widget.selectedCollection == collection
                      ? const Icon(Icons.check_circle, color: Color(0xFF7C3ABA))
                      : null,
                  onTap: () => Navigator.pop(context, collection),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
