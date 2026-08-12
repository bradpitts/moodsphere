import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/general_entry.dart';
import '../providers/general_entry_provider.dart';

class GeneralEntryScreen extends ConsumerStatefulWidget {
  const GeneralEntryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GeneralEntryScreen> createState() => _GeneralEntryScreenState();
}

class _GeneralEntryScreenState extends ConsumerState<GeneralEntryScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  XFile? _selectedPhotoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 75,
      );
      if (file != null) {
        setState(() { _selectedPhotoFile = file; });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image picker failed: $e')));
    }
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty || _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter both title and journal content.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? permanentPath;
      if (_selectedPhotoFile != null) {
        final docDir = await getApplicationDocumentsDirectory();
        final String safeName = _selectedPhotoFile!.name.isNotEmpty ? _selectedPhotoFile!.name : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String savedPath = '${docDir.path}/${DateTime.now().millisecondsSinceEpoch}_$safeName';
        final File savedFile = File(savedPath);
        await _selectedPhotoFile!.saveTo(savedFile.path);
        if (await savedFile.exists()) {
          permanentPath = savedFile.absolute.path;
        }
      }

      final newEntry = GeneralEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        photoPath: permanentPath,
      );

      await ref.read(generalEntryNotifierProvider.notifier).addEntry(newEntry);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save entry: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.of(context).pop()),
        title: Text('New Freeform Journal', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('JOURNAL TITLE', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Give your entry a title...',
                  filled: true, fillColor: const Color(0xFF1E1E2C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Text('JOURNAL THOUGHTS', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _contentController, maxLines: 7,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Write freely about your thoughts, ideas, or day...',
                  filled: true, fillColor: const Color(0xFF1E1E2C),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(_selectedPhotoFile != null ? Icons.image_outlined : Icons.add_photo_alternate_outlined, color: const Color(0xFFFFD700)),
                      label: Text(_selectedPhotoFile != null ? 'Change Photo' : 'Attach Image', style: GoogleFonts.inter(color: Colors.white)),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: BorderSide(color: Colors.white.withOpacity(0.15)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                  if (_selectedPhotoFile != null) ...[
                    const SizedBox(width: 12),
                    ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(_selectedPhotoFile!.path), width: 48, height: 48, fit: BoxFit.cover)),
                  ],
                ],
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveEntry,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.black) : Text('Save Journal Entry', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}