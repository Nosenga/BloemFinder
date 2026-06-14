import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Function(int)? onRatingChanged;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 32,
    this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= rating.ceil();
        
        return GestureDetector(
          onTap: onRatingChanged != null
              ? () => onRatingChanged!(starIndex)
              : null,
          child: Icon(
            isFilled ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: size,
          ),
        );
      }),
    );
  }
}