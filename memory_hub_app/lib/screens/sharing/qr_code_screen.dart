import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../design_system/design_system.dart';
import '../../design_system/layout/padded.dart';

class QRCodeScreen extends StatelessWidget {
  final String shareUrl;
  final String title;
  final String? description;

  const QRCodeScreen({
    Key? key,
    required this.shareUrl,
    required this.title,
    this.description,
  }) : super(key: key);

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: shareUrl));
    AppSnackbar.success(context, 'Link copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share via QR Code'),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [MemoryHubColors.indigo500, MemoryHubColors.purple500],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(Spacing.xxl),
        child: Column(
          children: [
            VGap.xl(),
            Text(
              title,
              style: context.text.headlineSmall?.copyWith(
                fontWeight: MemoryHubTypography.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              VGap.sm(),
              Text(
                description!,
                style: context.text.bodyMedium?.copyWith(
                  color: MemoryHubColors.gray600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            VGap.xxxl(),
            AppCard(
              child: Padded.xxl(
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(Spacing.lg),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: MemoryHubBorderRadius.mdRadius,
                        border: Border.all(color: MemoryHubColors.gray300),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(Spacing.lg),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: MemoryHubBorderRadius.smRadius,
                            ),
                            child: QrImageView(
                              data: shareUrl,
                              version: QrVersions.auto,
                              size: 250.0,
                              backgroundColor: Colors.white,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                              embeddedImage: null,
                            ),
                          ),
                          VGap.lg(),
                          Text(
                            'Scan this QR code to access',
                            style: context.text.bodySmall?.copyWith(
                              color: MemoryHubColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VGap.xxxl(),
            Text(
              'Share Link',
              style: context.text.bodyLarge?.copyWith(
                fontWeight: MemoryHubTypography.bold,
              ),
            ),
            VGap.md(),
            Container(
              padding: EdgeInsets.all(Spacing.lg),
              decoration: BoxDecoration(
                color: MemoryHubColors.gray100,
                borderRadius: MemoryHubBorderRadius.mdRadius,
                border: Border.all(color: MemoryHubColors.gray300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareUrl,
                      style: context.text.bodySmall?.copyWith(
                        color: MemoryHubColors.gray700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () => _copyToClipboard(context),
                    tooltip: 'Copy link',
                  ),
                ],
              ),
            ),
            VGap.xxl(),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                onPressed: () => _copyToClipboard(context),
                label: 'Copy Link',
                leading: const Icon(Icons.copy, size: 20),
              ),
            ),
            VGap.md(),
            SizedBox(
              width: double.infinity,
              child: SecondaryButton(
                onPressed: () {
                  AppSnackbar.info(context, 'Share functionality coming soon');
                },
                label: 'Share via...',
                leading: const Icon(Icons.share, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
