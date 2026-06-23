import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../models/chat_message_model.dart';
import '../../widgets/web_image/web_image.dart';
import '../../widgets/chat_bubble.dart';

class ChatMediaScreen extends StatefulWidget {
  final List<ChatMessageModel> messages;
  final String partnerName;

  const ChatMediaScreen({
    super.key,
    required this.messages,
    required this.partnerName,
  });

  @override
  State<ChatMediaScreen> createState() => _ChatMediaScreenState();
}

class _ChatMediaScreenState extends State<ChatMediaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<ChatMessageModel> _images = [];
  final List<ChatMessageModel> _files = [];
  final List<({ChatMessageModel message, String url})> _links = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _extractMedia();
  }

  void _extractMedia() {
    final linkRegex = RegExp(r'(https?:\/\/[^\s]+)');
    for (final m in widget.messages) {
      if (m.isDeleted) continue;
      
      // Images
      if (m.isImage) {
        _images.add(m);
      } 
      // Files (Documents)
      else if (m.isFile) {
        _files.add(m);
      } 
      // General messages containing links
      else if (m.messageText.isNotEmpty) {
        final matches = linkRegex.allMatches(m.messageText);
        for (final match in matches) {
          final url = match.group(0);
          if (url != null) {
            _links.add((message: m, url: url));
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _viewImage(ChatMessageModel message, String resolvedUrl) {
    if (resolvedUrl.isEmpty) return;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: buildWebFriendlyImage(
                      imageUrl: resolvedUrl,
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: MediaQuery.of(context).size.height * 0.7,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(resolvedUrl);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  icon: const Icon(Icons.download),
                  label: Text(isAr ? 'فتح للتحميل' : 'Open to Download'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isAr ? 'المحتوى المشترك' : 'Shared Media',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.secondary,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppColors.secondary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: isAr ? 'الصور' : 'Images'),
            Tab(text: isAr ? 'الملفات' : 'Files'),
            Tab(text: isAr ? 'الروابط' : 'Links'),
          ],
        ),
      ),
      body: Container(
        color: AppColors.background,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildImagesTab(isAr),
            _buildFilesTab(isAr),
            _buildLinksTab(isAr),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesTab(bool isAr) {
    if (_images.isEmpty) {
      return Center(
        child: Text(
          isAr ? 'لا توجد صور مشتركة' : 'No shared images',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.medium),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _images.length,
      itemBuilder: (context, i) {
        final msg = _images[i];
        final directUrl = msg.imageUrl;
        final hasDirectUrl = directUrl != null && directUrl.isNotEmpty;

        return Tooltip(
          message: isAr ? 'اضغط مطولاً للانتقال للرسالة' : 'Long press to jump to message',
          child: InkWell(
            onTap: hasDirectUrl ? () => _viewImage(msg, directUrl) : null,
            onLongPress: () {
              Navigator.pop(context, msg);
            },
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Hero(
                tag: 'media-img-${msg.id}',
                child: hasDirectUrl
                    ? buildWebFriendlyImage(
                        imageUrl: directUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : (msg.telegramFileId != null && msg.telegramFileId!.isNotEmpty
                        ? TelegramMediaWidget(
                            telegramFileId: msg.telegramFileId!,
                            builder: (context, url, isImage, fileName) {
                              return InkWell(
                                onTap: () => _viewImage(msg, url),
                                onLongPress: () {
                                  Navigator.pop(context, msg);
                                },
                                child: buildWebFriendlyImage(
                                  imageUrl: url,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          )),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilesTab(bool isAr) {
    if (_files.isEmpty) {
      return Center(
        child: Text(
          isAr ? 'لا توجد ملفات مشتركة' : 'No shared files',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.medium),
      itemCount: _files.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
      itemBuilder: (context, i) {
        final msg = _files[i];
        final formattedDate = '${msg.createdAt.day}/${msg.createdAt.month}/${msg.createdAt.year}';
        
        return Tooltip(
          message: isAr ? 'اضغط مطولاً للانتقال للرسالة' : 'Long press to jump to message',
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.insert_drive_file_rounded, color: Colors.white),
            ),
            title: Text(
              msg.fileName ?? (isAr ? 'ملف بدون اسم' : 'Unnamed file'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              formattedDate,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.open_in_new_rounded, color: AppColors.primary),
              onPressed: () async {
                final url = msg.fileUrl;
                if (url != null && url.isNotEmpty) {
                  final uri = Uri.parse(url);
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            onLongPress: () {
              Navigator.pop(context, msg);
            },
          ),
        );
      },
    );
  }

  Widget _buildLinksTab(bool isAr) {
    if (_links.isEmpty) {
      return Center(
        child: Text(
          isAr ? 'لا توجد روابط مشتركة' : 'No shared links',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.medium),
      itemCount: _links.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
      itemBuilder: (context, i) {
        final item = _links[i];
        final formattedDate = '${item.message.createdAt.day}/${item.message.createdAt.month}/${item.message.createdAt.year}';

        return Tooltip(
          message: isAr ? 'اضغط مطولاً للانتقال للرسالة' : 'Long press to jump to message',
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.link_rounded, color: Colors.white),
            ),
            title: Text(
              item.url,
              style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              formattedDate,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            onTap: () async {
              final uri = Uri.parse(item.url);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            onLongPress: () {
              Navigator.pop(context, item.message);
            },
          ),
        );
      },
    );
  }
}
