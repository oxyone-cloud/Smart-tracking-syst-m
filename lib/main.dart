import 'package:flutter_map/flutter_map.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init check: $e");
  }
  runApp(const MaterialApp(
    home: RealtimeTrackingMap(),
    debugShowCheckedModeBanner: false,
  ));
}

class StoreLocation {
  final String name;
  final LatLng location;
  final bool isHyper;

  StoreLocation({required this.name, required this.location, required this.isHyper});
}

class TruckLocation {
  final String id;
  String name;
  LatLng position;
  final Color color;

  TruckLocation({
    required this.id,
    required this.name,
    required this.position,
    required this.color,
  });
}

class DemoVideo {
  final String title;
  final String description;
  final String url;
  final IconData icon;

  DemoVideo({
    required this.title,
    required this.description,
    required this.url,
    required this.icon,
  });
}

class RealtimeTrackingMap extends StatefulWidget {
  const RealtimeTrackingMap({super.key});

  @override
  State<RealtimeTrackingMap> createState() => _RealtimeTrackingMapState();
}

class _RealtimeTrackingMapState extends State<RealtimeTrackingMap> {
  final List<TruckLocation> _trucks = [
    TruckLocation(
      id: "camion_01_centre",
      name: "Camion 01 (Centre-ville)",
      position: const LatLng(35.6911, -0.6322),
      color: Colors.deepOrange,
    ),
    TruckLocation(
      id: "camion_02_akid",
      name: "Camion 02 (Akid Lotfi)",
      position: const LatLng(35.7085, -0.5831),
      color: Colors.blueAccent,
    ),
    TruckLocation(
      id: "camion_03_senia",
      name: "Camion 03 (Es Senia)",
      position: const LatLng(35.6480, -0.6180),
      color: Colors.green,
    ),
    TruckLocation(
      id: "camion_04_bireldjir",
      name: "Camion 04 (Bir El Djir)",
      position: const LatLng(35.7220, -0.5480),
      color: Colors.purple,
    ),
  ];

  final List<DemoVideo> _demoVideos = [
    DemoVideo(
      title: "OxyONE Labs : Révolutionner le Froid Connecté",
      description: "Contrôlez, sécurisez et surveillez votre chaîne du froid à distance.",
      url: "https://www.youtube.com/watch?v=tORNQBHefck",
      icon: Icons.ac_unit,
    ),
    DemoVideo(
      title: "Cold service Application",
      description: "Application premium logistique et traçabilité absolue en temps réel.",
      url: "https://www.youtube.com/watch?v=n-WfnjMn1aA",
      icon: Icons.local_shipping,
    ),
  ];

  StreamSubscription<Position>? _positionStream;
  Timer? _simulationTimer;
  Timer? _popupTimer;
  bool _isSimulating = true;
  bool _dialogShown = false;
  final MapController _mapController = MapController();
  final Random _random = Random();
  List<StoreLocation> _stores = [];

  @override
  void initState() {
    super.initState();
    _fetchSupermarkets();
    _startTrackingOrSimulation();
  }

  Future<void> _fetchSupermarkets() async {
    final overpassUrl = Uri.parse(
      'https://overpass-api.de/api/interpreter?data=[out:json];node["shop"~"supermarket|hypermarket"](35.5, -0.8, 35.8, -0.4);out body;',
    );

    try {
      final response = await http.get(overpassUrl);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List elements = data['elements'] ?? [];

        List<StoreLocation> loadedStores = [];
        for (var elem in elements) {
          final lat = elem['lat'];
          final lon = elem['lon'];
          final tags = elem['tags'] ?? {};
          final name = tags['name'] ?? (tags['shop'] == 'hypermarket' ? 'Hypermarché' : 'Supermarché');
          final isHyper = tags['shop'] == 'hypermarket';

          if (lat != null && lon != null) {
            loadedStores.add(StoreLocation(
              name: name,
              location: LatLng(lat, lon),
              isHyper: isHyper,
            ));
          }
        }

        if (mounted) {
          setState(() {
            _stores = loadedStores;
          });
        }
      }
    } catch (e) {
      debugPrint("Erreur de chargement des magasins: $e");
    }
  }

  void _startTrackingOrSimulation() {
    if (_isSimulating) {
      _positionStream?.cancel();
      _trucks[0].name = "Camion 01 (Centre-ville)";
      _startSimulation();
      _start10SecondPopupTimer();
    } else {
      _simulationTimer?.cancel();
      _popupTimer?.cancel();
      _trucks[0].name = "Votre position";
      _initLocationTracking();
    }
  }

  void _start10SecondPopupTimer() {
    _popupTimer?.cancel();
    _dialogShown = false;
    _popupTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isSimulating && !_dialogShown) {
        _showPremiumDialog();
      }
    });
  }

  void _showPremiumDialog() {
    _dialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
              SizedBox(width: 10),
              Text(
                "Version Premium OxyONE",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "L'application est actuellement sous la version Premium.",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                "Pour plus de détails, d'informations ou pour l'activation des fonctionnalités avancées de la chaîne du froid, veuillez contacter :",
                style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.7)),
              ),
              const SizedBox(height: 12),
              const SelectableText(
                " Benhamamouch Othman (Alias oxyone)\n Téléphone : +213 782 09 02 81",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A365D),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A365D),
                foregroundColor: Colors.white,
              ),
              child: const Text("Fermer"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showVideosDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.ondemand_video, color: Colors.redAccent, size: 28),
              SizedBox(width: 10),
              Text("Vidéos Démo OxyONE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _demoVideos.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final video = _demoVideos[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red[50],
                    child: Icon(video.icon, color: Colors.redAccent),
                  ),
                  title: Text(video.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(video.description, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.play_circle_fill, color: Colors.redAccent, size: 30),
                  onTap: () {
                    html.window.open(video.url, '_blank');
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Fermer"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _startSimulation() {
    for (var truck in _trucks) {
      _saveToFirestore(truck.id, truck.position.latitude, truck.position.longitude, isSimulated: true);
    }

    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          for (var truck in _trucks) {
            double newLat = truck.position.latitude + (_random.nextDouble() - 0.5) * 0.0015;
            double newLng = truck.position.longitude + (_random.nextDouble() - 0.5) * 0.0015;
            truck.position = LatLng(newLat, newLng);

            _saveToFirestore(truck.id, newLat, newLng, isSimulated: true);
          }
        });
      }
    });
  }

  Future<void> _initLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (!_isSimulating && mounted) {
        final realPos = LatLng(position.latitude, position.longitude);
        setState(() {
          _trucks[0].position = realPos;
          _trucks[0].name = "Votre position";
        });
        _mapController.move(realPos, _mapController.camera.zoom);
        _saveToFirestore(_trucks[0].id, position.latitude, position.longitude, isSimulated: false);
      }
    });
  }

  Future<void> _saveToFirestore(String truckId, double lat, double lng, {required bool isSimulated}) async {
    try {
      await FirebaseFirestore.instance
          .collection('visitors_locations')
          .doc(truckId)
          .set({
        'visitorId': truckId,
        'type': 'camion_frigo',
        'latitude': lat,
        'longitude': lng,
        'isSimulated': isSimulated,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Erreur Firestore ($truckId): $e");
    }
  }

  void _downloadCertificateHtml(String lang) {
    bool isFr = lang == 'FR';
    String title = isFr ? "Certificat d'Architecture & Validation Technique" : "Architecture & Technical Validation Certificate";
    String subtitle = isFr ? "Application OxyONE - Smart Tracking & Cold Chain Analytics" : "OxyONE Application - Smart Tracking & Cold Chain Analytics";
    String badge = isFr ? "Document Officiel de Conformité Software" : "Official Software Compliance Document";

    String htmlContent = '''
<!DOCTYPE html>
<html lang="${lang.toLowerCase()}">
<head>
<meta charset="UTF-8">
<title>$title</title>
<style>
  body { font-family: Arial, sans-serif; color: #2c3e50; line-height: 1.6; padding: 20px; max-width: 800px; margin: auto; }
  .header { background: #1a365d; color: white; padding: 20px; border-bottom: 4px solid #2b6cb0; border-radius: 6px; }
  .badge { background: #2b6cb0; color: white; padding: 3px 8px; border-radius: 3px; font-size: 11px; font-weight: bold; }
  .meta-table, .data-table { width: 100%; border-collapse: collapse; margin-top: 15px; }
  .meta-table td, .data-table th, .data-table td { border: 1px solid #cbd5e0; padding: 8px 12px; font-size: 13px; }
  .data-table th { background: #2b6cb0; color: white; }
  .callout { background: #ebf8ff; border-left: 4px solid #3182ce; padding: 12px; margin: 15px 0; font-size: 13px; }
  .stamp { border: 2px dashed #805ad5; color: #6b46c1; padding: 10px; text-align: center; font-weight: bold; margin-top: 15px; }
</style>
</head>
<body>
<div class="header">
  <h2>$title</h2>
  <div>$subtitle</div>
  <br><span class="badge">$badge</span>
</div>
<table class="meta-table">
  <tr><td><b>App:</b> OxyONE Smart Tracking</td><td><b>Version:</b> 2.4.0</td></tr>
  <tr><td><b>Ecosystem:</b> OxyONE / Cold Service</td><td><b>Date:</b> September 23, 2026</td></tr>
  <tr><td><b>Author:</b> Othman Benhamamouch</td><td><b>Status:</b> <span style="color:green; font-weight:bold;">PASSED / CONFORME</span></td></tr>
</table>
<h3>${isFr ? "1. Spécifications & Stack Technologique" : "1. Technical Specifications & Stack"}</h3>
<table class="data-table">
  <tr><th>Component</th><th>Technology</th><th>Role</th></tr>
  <tr><td>Frontend</td><td>Flutter (Web/Mobile)</td><td>UI & Map Visuals (flutter_map)</td></tr>
  <tr><td>Backend</td><td>Firebase Firestore</td><td>Real-time Tracking Database</td></tr>
  <tr><td>GIS API</td><td>OpenStreetMap / Overpass</td><td>POI Store Mapping</td></tr>
  <tr><td>Hosting</td><td>Firebase Hosting</td><td>Cloud Infrastructure</td></tr>
</table>
<h3>${isFr ? "2. Droits de Propriété Intellectuelle" : "2. Intellectual Property Rights"}</h3>
<div class="callout">
  ${isFr ? "L'application OxyONE et l'ouvrage 'L'Usine du Futur dans le Secteur du Froid' sont protégés par la <b>Convention de Berne</b>." : "OxyONE application and the book 'L'Usine du Futur dans le Secteur du Froid' are protected under the <b>Berne Convention</b>."}
</div>
<div class="stamp">SSCI SOLUTION OF COLD - OxyONE Ecosystem Certified</div>
</body>
</html>
''';

    final blob = html.Blob([htmlContent], 'text/html');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "Certificat_Technique_OxyONE_$lang.html")
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Certificat $lang téléchargé !"),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  void _exportToExcel() {
    var excel = excel_pkg.Excel.createExcel();
    excel_pkg.Sheet truckSheet = excel['Flotte Camions'];
    
    if (excel.tables.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    truckSheet.appendRow([
      excel_pkg.TextCellValue('ID Camion'),
      excel_pkg.TextCellValue('Nom du Camion'),
      excel_pkg.TextCellValue('Latitude'),
      excel_pkg.TextCellValue('Longitude'),
      excel_pkg.TextCellValue('Mode Simulation'),
      excel_pkg.TextCellValue('Horodatage Export'),
    ]);

    String nowStr = DateTime.now().toIso8601String();
    
    for (var truck in _trucks) {
      truckSheet.appendRow([
        excel_pkg.TextCellValue(truck.id),
        excel_pkg.TextCellValue(truck.name),
        excel_pkg.DoubleCellValue(truck.position.latitude),
        excel_pkg.DoubleCellValue(truck.position.longitude),
        excel_pkg.TextCellValue(_isSimulating ? "Oui (Actif)" : "Non (GPS Réel)"),
        excel_pkg.TextCellValue(nowStr),
      ]);
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final blob = html.Blob(
        [fileBytes],
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "OxyONE_Flotte_${DateTime.now().millisecondsSinceEpoch}.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _simulationTimer?.cancel();
    _popupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSimulating ? "Flotte OxyONE" : "GPS Réel"),
        backgroundColor: _isSimulating ? Colors.orange[800] : Colors.blueAccent,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.play_circle_fill, size: 20),
            label: const Text("Vidéos Démo", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: _showVideosDialog,
          ),
          const SizedBox(width: 8),
          Switch(
            value: _isSimulating,
            activeColor: Colors.white,
            onChanged: (value) {
              setState(() {
                _isSimulating = value;
              });
              _startTrackingOrSimulation();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'excel') {
                _exportToExcel();
              } else if (value == 'cert_fr') {
                _downloadCertificateHtml('FR');
              } else if (value == 'cert_en') {
                _downloadCertificateHtml('EN');
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.file_download, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Exporter Excel"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cert_fr',
                child: Row(
                  children: [
                    Icon(Icons.card_membership, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text("Certificat FR"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cert_en',
                child: Row(
                  children: [
                    Icon(Icons.verified, color: Colors.indigo),
                    SizedBox(width: 8),
                    Text("Certificat EN"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _trucks[0].position,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.oxyone.smart_tracking_project',
          ),
          MarkerLayer(
            markers: [
              ..._stores.map((store) {
                return Marker(
                  point: store.location,
                  width: 90,
                  height: 90,
                  child: Column(
                    children: [
                      Icon(
                        store.isHyper ? Icons.storefront : Icons.shopping_cart,
                        color: store.isHyper ? Colors.red : Colors.teal,
                        size: 30,
                      ),
                      Text(store.name, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
              ..._trucks.asMap().entries.map((entry) {
                int index = entry.key;
                var truck = entry.value;
                bool isUserPosition = !_isSimulating && index == 0;

                return Marker(
                  point: truck.position,
                  width: 100,
                  height: 90,
                  child: Column(
                    children: [
                      Icon(
                        isUserPosition ? Icons.my_location : Icons.local_shipping,
                        color: isUserPosition ? Colors.blue : truck.color,
                        size: isUserPosition ? 34 : 32,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: isUserPosition ? Colors.blue : Colors.white70,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          truck.name,
                          style: TextStyle(
                            fontSize: 9,
                            color: isUserPosition ? Colors.white : truck.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
