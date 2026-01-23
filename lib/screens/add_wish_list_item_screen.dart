import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/bucket_list_category.dart';
import '../services/bucket_list_service.dart';
import '../services/wish_list_service.dart';
import '../services/supabase_service.dart';
import 'wish_list_success_screen.dart';

class AddWishListItemScreen extends StatefulWidget {
  const AddWishListItemScreen({super.key});

  @override
  State<AddWishListItemScreen> createState() => _AddWishListItemScreenState();
}

class _AddWishListItemScreenState extends State<AddWishListItemScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _linksController = TextEditingController();
  
  BucketListCategory? _selectedCategory;
  bool _isSurprise = false;
  String _wishFor = 'Me';
  bool _isPrivate = false;
  bool _isLoading = false;
  bool _isSaving = false;
  
  final List<_ThemeOption> _themeOptions = const [
    _ThemeOption(label: 'Pink', color: Color(0xFFFFB7C3)),
    _ThemeOption(label: 'Blue', color: Color(0xFF6EB4FF)),
    _ThemeOption(label: 'Yellow', color: Color(0xFFF4D100)),
    _ThemeOption(label: 'Purple', color: Color(0xFFC8A8E9)),
  ];
  
  _ThemeOption _selectedTheme = const _ThemeOption(label: 'Pink', color: Color(0xFFFFB7C3));

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _linksController.dispose();
    super.dispose();
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
        const SnackBar(content: Text('Please enter an item name')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      // OPTIMISTIC UI: We prepare the navigation info before awaiting the server
      final currentUser = SupabaseService.currentUser;
      String partnerName = 'Partner';
      // ... (In a real app, we might get this from a local provider/cache)

      // Start the save operation
      final saveFuture = WishListService.addWishListItem(
        title: title,
        categoryId: _selectedCategory?.id,
        notes: _notesController.text.trim(),
        links: _linksController.text.trim(),
        themeColor: _themeHex(_selectedTheme),
        isSurprise: _isSurprise,
        wishFor: _wishFor,
        isPrivate: _isPrivate,
      );

      // Optimistically navigate to success screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WishListSuccessScreen(
              title: title,
              categoryName: _selectedCategory?.name ?? 'Wish',
              themeColor: _selectedTheme.color,
              wishFor: _wishFor,
              partnerName: partnerName,
              // These will be null but the screen can handle it or we can pass placeholders
              userImageUrl: null, 
              partnerImageUrl: null,
            ),
          ),
        );
      }

      // Await in the background
      await saveFuture;

    } catch (e) {
      debugPrint('Error saving wish list item: $e');
      // Rollback logic would go here if we didn't navigate away
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
          'Add a Item to Wish List',
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
            _buildLabel('Item Name'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleController,
              hint: 'Name of the item',
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

            _buildLabel('Notes'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _notesController,
              hint: 'A text area for "Internal Jokes" or specific things not to forget, budget, sizes etc',
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
              'Surprise me',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'By default, your partner can see the details of this wish. Switch this on to hide the specifics and keep them guessing until the big reveal',
              style: GoogleFonts.manrope(
                fontSize: 14,
                color: const Color(0xFF4D4B4B),
              ),
            ),
            const SizedBox(height: 16),
            Switch(
              value: _isSurprise,
              onChanged: (val) => setState(() => _isSurprise = val),
              activeColor: const Color(0xFF7C3ABA),
            ),
            const SizedBox(height: 24),

            _buildLabel('Who is this wish for (you or your partner)'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFFC8A8E9).withOpacity(0.5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _wishFor,
                  isExpanded: true,
                  items: ['Me', 'Partner'].map((val) => DropdownMenuItem(
                    value: val,
                    child: Text(val, style: GoogleFonts.manrope()),
                  )).toList(),
                  onChanged: (val) => setState(() => _wishFor = val ?? 'Me'),
                ),
              ),
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
