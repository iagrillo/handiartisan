import 'package:flutter/material.dart';
import 'package:handihub_artisan_app/models/artisan.dart';

class EditArtisanProfilePage extends StatelessWidget {
  final Artisan artisan;
  final String email;
  final String phone;
  const EditArtisanProfilePage(
      {required this.artisan,
      required this.email,
      required this.phone,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Artisan Profile')),
      body: Center(child: Text('Edit profile for ${artisan.fullName}')),
    );
  }
}
