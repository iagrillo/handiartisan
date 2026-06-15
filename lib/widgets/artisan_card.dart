import 'package:flutter/material.dart';
import 'package:handihub_artisan_app/models/artisan.dart';

class ArtisanCard extends StatelessWidget {
  final Artisan artisan;
  const ArtisanCard({required this.artisan, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(artisan.fullName),
        subtitle: Text(artisan.category),
      ),
    );
  }
}
