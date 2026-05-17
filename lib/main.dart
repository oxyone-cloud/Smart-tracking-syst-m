import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const OxyOneApp());
}

class OxyOneApp extends StatelessWidget {
  const OxyOneApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OxyONE Ecosystem',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const OxyOneMainScreen(),
    );
  }
}

class OxyOneMainScreen extends StatefulWidget {
  const OxyOneMainScreen({Key? key}) : super(key: key);

  @override
  State<OxyOneMainScreen> createState() => _OxyOneMainScreenState();
}

class _OxyOneMainScreenState extends State<OxyOneMainScreen> {
  static const CameraPosition _oranCenter = CameraPosition(
    target: LatLng(35.6911, -0.6417),
    zoom: 12.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. CARTE DE FOND (NATIVE)
          const GoogleMap(
            initialCameraPosition: _oranCenter,
            mapType: MapType.normal,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 2. INTERFACE SUPERPOSÉE (HUD)
          Positioned(
            top: 50,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHudWidget(
                  title: "DIGITAL SENSE",
                  subtitle: "DATA VAULT",
                  details: "BERNE CONVENTION PROTECTED",
                  accentColor: const Color(0xFF238636),
                ),
                const SizedBox(height: 15),
                _buildHudWidget(
                  title: "SMART TRACKING",
                  subtitle: "OPS MANAGER",
                  details: "FLOTTE : OXYONE_01 (ORAN)",
                  accentColor: const Color(0xFF58a6ff),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudWidget({
    required String title,
    required String subtitle,
    required String details,
    required Color accentColor,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117).withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFFE6EDF3), fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            details,
            style: const TextStyle(color: Color(0xFF8B949E), fontSize: 9, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
