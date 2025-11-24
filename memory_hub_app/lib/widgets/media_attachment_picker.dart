import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../design_system/design_tokens.dart';
import 'dart:io';

enum MediaType { image, video, audio }

class MediaAttachment {
  final String path;
  final MediaType type;
  final String? name;

  MediaAttachment({required this.path, required this.type, this.name});
}

class MediaAttachmentPicker extends StatefulWidget {
  final List<MediaAttachment> initialAttachments;
  final Function(List<MediaAttachment>) onAttachmentsChanged;
  final int maxAttachments;

  const MediaAttachmentPicker({
    Key? key,
    this.initialAttachments = const [],
    required this.onAttachmentsChanged,
    this.maxAttachments = 5,
  }) : super(key: key);

  @override
  State<MediaAttachmentPicker> createState() => _MediaAttachmentPickerState();
}

class _MediaAttachmentPickerState extends State<MediaAttachmentPicker> {
  late List<MediaAttachment> _attachments;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _attachments = List.from(widget.initialAttachments);
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_attachments.length >= widget.maxAttachments) {
      _showMaxLimitMessage();
      return;
    }

    try {
      final XFile? image = await _imagePicker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _attachments.add(MediaAttachment(
            path: image.path,
            type: MediaType.image,
            name: image.name,
          ));
        });
        widget.onAttachmentsChanged(_attachments);
      }
    } catch (e) {
      _showErrorMessage('Failed to pick image: $e');
    }
  }

  Future<void> _pickVideo() async {
    if (_attachments.length >= widget.maxAttachments) {
      _showMaxLimitMessage();
      return;
    }

    try {
      final XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        setState(() {
          _attachments.add(MediaAttachment(
            path: video.path,
            type: MediaType.video,
            name: video.name,
          ));
        });
        widget.onAttachmentsChanged(_attachments);
      }
    } catch (e) {
      _showErrorMessage('Failed to pick video: $e');
    }
  }

  Future<void> _pickAudio() async {
    if (_attachments.length >= widget.maxAttachments) {
      _showMaxLimitMessage();
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _attachments.add(MediaAttachment(
            path: result.files.single.path!,
            type: MediaType.audio,
            name: result.files.single.name,
          ));
        });
        widget.onAttachmentsChanged(_attachments);
      }
    } catch (e) {
      _showErrorMessage('Failed to pick audio: $e');
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
    widget.onAttachmentsChanged(_attachments);
  }

  void _showMaxLimitMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Maximum ${widget.maxAttachments} attachments allowed')),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: MemoryHubColors.red600),
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: MemoryHubColors.blue600),
              title: const Text('Photo from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: MemoryHubColors.green600),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: MemoryHubColors.purple600),
              title: const Text('Select Video'),
              onTap: () {
                Navigator.pop(context);
                _pickVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.audiotrack, color: MemoryHubColors.orange500),
              title: const Text('Select Audio'),
              onTap: () {
                Navigator.pop(context);
                _pickAudio();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview(MediaAttachment attachment, int index) {
    IconData icon;
    Color color;

    switch (attachment.type) {
      case MediaType.image:
        icon = Icons.image;
        color = MemoryHubColors.blue600;
        break;
      case MediaType.video:
        icon = Icons.videocam;
        color = MemoryHubColors.purple600;
        break;
      case MediaType.audio:
        icon = Icons.audiotrack;
        color = MemoryHubColors.orange500;
        break;
    }

    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: MemoryHubBorderRadius.mdRadius,
      ),
      child: Stack(
        children: [
          // Preview
          Center(
            child: attachment.type == MediaType.image && File(attachment.path).existsSync()
                ? ClipRRect(
                    borderRadius: MemoryHubBorderRadius.mdRadius,
                    child: Image.file(
                      File(attachment.path),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(icon, size: 40, color: color),
          ),
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeAttachment(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
          // File name
          if (attachment.name != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Text(
                  attachment.name!,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.attach_file, size: 20),
            const SizedBox(width: 8),
            const Text('Attachments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (_attachments.length < widget.maxAttachments)
              OutlinedButton.icon(
                onPressed: _showMediaOptions,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Media'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_attachments.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              borderRadius: MemoryHubBorderRadius.mdRadius,
            ),
            child: Row(
              children: [
                Icon(Icons.photo_library, color: Colors.grey.shade400),
                const SizedBox(width: 8),
                Text('No attachments', style: TextStyle(color: Colors.grey.shade600)),
                const Spacer(),
                Text(
                  'Photos, Videos, Audio',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          )
        else
          Wrap(
            children: _attachments.asMap().entries.map((entry) {
              return _buildAttachmentPreview(entry.value, entry.key);
            }).toList(),
          ),
      ],
    );
  }
}
