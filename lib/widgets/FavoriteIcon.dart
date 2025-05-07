import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteIcon extends StatefulWidget {
  final String vehicleId;
  final double size;
  final ValueChanged<bool>? onToggle; // Add this line


  const FavoriteIcon({
    Key? key,
    required this.vehicleId,
    this.size = 20,
    this.onToggle, // Add this
  }) : super(key: key);

  @override
  _FavoriteIconState createState() => _FavoriteIconState();
}

class _FavoriteIconState extends State<FavoriteIcon> {
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  // Check if the vehicle is in favorites
  Future<void> _checkIfFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];
    setState(() {
      isFavorite = favorites.contains(widget.vehicleId);
    });
  }

  // Toggle favorite status
  Future<void> _toggleFavorite() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];

    if (isFavorite) {
      favorites.remove(widget.vehicleId);
    } else {
      favorites.add(widget.vehicleId);
    }

    await prefs.setStringList('favorites', favorites);

    setState(() {
      isFavorite = !isFavorite;
    });

    if (widget.onToggle != null) {
      widget.onToggle!(isFavorite); // 🔥 Notify parent of the new state
    }
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleFavorite,
      child: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? Colors.red : Colors.white,
        size: widget.size,
      ),
    );
  }
}
