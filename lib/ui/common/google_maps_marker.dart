import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wonders_opentelemetry/assets.dart';

Marker getMapsMarker(LatLng position) => Marker(
      markerId: MarkerId('0'),
      position: position,
      icon: AppBitmaps.mapMarker,
    );
