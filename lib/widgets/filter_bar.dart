import 'package:flutter/material.dart';

class FilterBar extends StatefulWidget {
  final Function(int? maxPrice, String? roomType, bool? hasWifi) onFilterChanged;
  
  const FilterBar({
    super.key,
    required this.onFilterChanged,
  });

  @override
  State<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<FilterBar> {
  int? selectedMaxPrice;
  String? selectedRoomType;
  bool? hasWifi;
  
  final List<int> priceOptions = [1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000];
  final List<String> roomTypeOptions = ['single', 'shared', 'studio', 'flat'];

  void _applyFilters() {
    widget.onFilterChanged(selectedMaxPrice, selectedRoomType, hasWifi);
  }

  void _clearFilters() {
    setState(() {
      selectedMaxPrice = null;
      selectedRoomType = null;
      hasWifi = null;
    });
    widget.onFilterChanged(null, null, null);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Price filter dropdown
          Expanded(
            child: DropdownButtonFormField<int>(
              value: selectedMaxPrice,
              hint: const Text('Max Price'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: priceOptions.map((price) {
                return DropdownMenuItem(
                  value: price,
                  child: Text('R$price'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedMaxPrice = value;
                });
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          
          // Room type filter dropdown
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedRoomType,
              hint: const Text('Room Type'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: roomTypeOptions.map((type) {
                String label;
                switch (type) {
                  case 'single': label = 'Single';
                  case 'shared': label = 'Shared';
                  case 'studio': label = 'Studio';
                  case 'flat': label = 'Flat/Apartment';
                  default: label = type;
                }
                return DropdownMenuItem(
                  value: type,
                  child: Text(label),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedRoomType = value;
                });
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          
          // Clear filters button
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearFilters,
            tooltip: 'Clear filters',
          ),
        ],
      ),
    );
  }
}