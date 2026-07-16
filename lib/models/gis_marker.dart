import 'package:flutter/material.dart';

class GisMarker {
  final String title;
  final String date;
  final String category; // Crime (Kejahatan), Accident (Kecelakaan)
  final String locationName;
  final String chronology;
  final Offset position; // Relative position on mock map grid (0.0 to 1.0)
  final double latitude;
  final double longitude;
  final String? imagePath;

  const GisMarker({
    required this.title,
    required this.date,
    required this.category,
    required this.locationName,
    required this.chronology,
    required this.position,
    required this.latitude,
    required this.longitude,
    this.imagePath,
  });
}

