import 'dart:convert';
import 'package:dgis_flutter/dgis_flutter.dart' as dgis;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lectures/env.dart';

class DGisLocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const DGisLocationPicker({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<DGisLocationPicker> createState() => _DGisLocationPickerState();
}

class _DGisLocationPickerState extends State<DGisLocationPicker> {
  late dgis.GisMapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = dgis.GisMapController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Выберите местоположение')),
      body: Stack(
        children: [
          dgis.GisMap(
            mapKey: Env.dgApiKey,
            directoryKey: Env.dgApiKey,
            controller: _mapController,
            startCameraPosition: dgis.GisCameraPosition(
              latitude: widget.initialLat ?? 55.751244,
              longitude: widget.initialLng ?? 37.618423,
              zoom: 15,
            ),
            onTapMarker: (dgis.GisMapMarker marker) {
              print("Marker tapped: ${marker.id}");
            },
          ),
          const Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Icon(Icons.location_pin, color: Colors.red, size: 50),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  final currentPosition =
                      await _mapController.getCameraPosition();
                  final url =
                      'https://catalog.api.2gis.com/3.0/items/by_point?lat=${currentPosition.latitude}&lon=${currentPosition.longitude}&key=${Env.dgApiKey}';
                  final response = await http.get(Uri.parse(url));

                  Map<String, dynamic> result = {
                    'lat': currentPosition.latitude,
                    'lng': currentPosition.longitude,
                  };

                  if (response.statusCode == 200) {
                    print('2GIS API Response: ${response.body}');
                    final data = json.decode(response.body);
                    final items = data['result']?['items'] as List?;
                    if (items != null && items.isNotEmpty) {
                      result['street'] =
                          items.first['address_name']?.split(',').first;
                      result['building'] = items.first['building_name'];
                    }
                  }
                  Navigator.of(context).pop(result);
                } catch (e) {
                  print("Error getting current camera position: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ошибка при выборе местоположения.'),
                    ),
                  );
                }
              },
              child: const Text('Выбрать это место'),
            ),
          ),
        ],
      ),
    );
  }
}
