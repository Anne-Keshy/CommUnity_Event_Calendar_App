import 'package:community/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class PhotoGalleryScreen extends StatefulWidget {
  final String eventId;

  const PhotoGalleryScreen({super.key, required this.eventId});

  @override
  _PhotoGalleryScreenState createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<PhotoGalleryScreen> {
  late Future<List<String>> _photosFuture;

  @override
  void initState() {
    super.initState();
    _photosFuture = ApiService().getEventPhotos(widget.eventId);
  }

  Future<void> _uploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final success =
          await ApiService().uploadEventPhoto(widget.eventId, pickedFile.path);
      if (success) {
        // Refresh the gallery
        if (mounted) {
          setState(() {
            _photosFuture = ApiService().getEventPhotos(widget.eventId);
          });
        }
      } else {
        // Show an error message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload photo.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Photo Gallery",
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<String>>(
        future: _photosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No photos yet."));
          }

          final photos = snapshot.data!;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4.0,
              mainAxisSpacing: 4.0,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return Image.network(photos[index], fit: BoxFit.cover);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadPhoto,
        backgroundColor: const Color(0xFF6C5CE7),
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
