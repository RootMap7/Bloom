import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/interest.dart';
import '../services/profile_details_service.dart';

class InterestsModal extends StatefulWidget {
  final List<Interest> initialSelectedInterests;

  const InterestsModal({
    super.key,
    required this.initialSelectedInterests,
  });

  @override
  State<InterestsModal> createState() => _InterestsModalState();
}

class _InterestsModalState extends State<InterestsModal> {
  List<Interest> _allInterests = [];
  final List<Interest> _selectedInterests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedInterests.addAll(widget.initialSelectedInterests);
    _loadInterests();
  }

  Future<void> _loadInterests() async {
    try {
      debugPrint('Fetching available interests...');
      final interests = await ProfileDetailsService.fetchAllAvailableInterests();
      debugPrint('Loaded ${interests.length} interests');
      
      if (mounted) {
        setState(() {
          _allInterests = interests;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading interests: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load interests: $e')),
        );
      }
    }
  }

  void _toggleInterest(Interest interest) {
    setState(() {
      final isSelected = _selectedInterests.any((i) => i.id == interest.id);
      if (isSelected) {
        _selectedInterests.removeWhere((i) => i.id == interest.id);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  Map<String, List<Interest>> _groupInterests() {
    // Categories in the order they should appear based on the user's provided list
    final List<String> categoryOrder = [
      'Food & Drink',
      'Travel & Adventure',
      'Home & Lifestyle',
      'Creativity & Hobbies',
      'Wellness & Connection',
      'Entertainment'
    ];

    final Map<String, List<Interest>> groups = {};
    
    // Initialize groups in the desired order
    for (var cat in categoryOrder) {
      groups[cat] = [];
    }

    for (var interest in _allInterests) {
      if (groups.containsKey(interest.category)) {
        groups[interest.category]!.add(interest);
      } else {
        // Fallback for any categories not in our order list
        groups.putIfAbsent(interest.category, () => []).add(interest);
      }
    }
    
    // Remove empty categories if no interests were found for them
    groups.removeWhere((key, value) => value.isEmpty);
    
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groupedInterests = _groupInterests();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interests',
                      style: GoogleFonts.manrope(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F1F1F),
                      ),
                    ),
                    Text(
                      'Select your interests',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 28),
                    color: const Color(0xFF1F1F1F),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedInterests.length} selected',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4D4B4B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_selectedInterests.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedInterests.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final interest = _selectedInterests[index];
                  return Chip(
                    label: Text(
                      interest.name,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    backgroundColor: const Color(0xFF7C3ABA),
                    deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white),
                    onDeleted: () => _toggleInterest(interest),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : groupedInterests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.interests_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No interests available yet',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                color: const Color(0xFF757575),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: groupedInterests.length,
                        itemBuilder: (context, index) {
                      final category = groupedInterests.keys.elementAt(index);
                      final interests = groupedInterests[category]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              category,
                              style: GoogleFonts.manrope(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F1F1F),
                              ),
                            ),
                          ),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: interests.map((interest) {
                              final isSelected = _selectedInterests.any((i) => i.id == interest.id);
                              return GestureDetector(
                                onTap: () => _toggleInterest(interest),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF7C3ABA) : Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isSelected ? Colors.transparent : const Color(0xFF4D4B4B),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    interest.name,
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? Colors.white : const Color(0xFF4D4B4B),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selectedInterests),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3ABA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
