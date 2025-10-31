import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/DocumentModel.dart';
import '../../api/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../utils/colors.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({Key? key}) : super(key: key);

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  List<FolderModel> _folders = [];
  List<DocumentModel> _documents = [];
  bool _isLoading = true;
  bool _isLoadingDocuments = false;
  String? _errorMessage;
  FolderModel? _selectedFolder;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        setState(() {
          _errorMessage = 'Non authentifié';
          _isLoading = false;
        });
        return;
      }

      final response = await apiClient.getAllFolders(token);

      if (response.success && response.data != null) {
        setState(() {
          _folders = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Erreur lors du chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFolderDocuments(FolderModel folder) async {
    setState(() {
      _selectedFolder = folder;
      _isLoadingDocuments = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        setState(() {
          _errorMessage = 'Non authentifié';
          _isLoadingDocuments = false;
        });
        return;
      }

      final response = await apiClient.getFolderDocuments(folder.id, token);

      if (response.success && response.data != null) {
        setState(() {
          _documents = response.data!;
          _isLoadingDocuments = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Erreur lors du chargement';
          _isLoadingDocuments = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoadingDocuments = false;
      });
    }
  }

  Future<void> _openDocument(DocumentModel document) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Non authentifié'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final url = apiClient.getDocumentDownloadUrl(document.id, token);

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir le document'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _goBack() {
    if (_selectedFolder != null) {
      setState(() {
        _selectedFolder = null;
        _documents = [];
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.white.withOpacity(0.3),
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : const Color(0xFF6366F1),
                ),
                onPressed: _goBack,
              ),
              title: Text(
                _selectedFolder != null
                    ? _selectedFolder!.name
                    : 'Documents',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF6366F1),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: isDark ? Colors.white : const Color(0xFF6366F1),
                  ),
                  onPressed: () {
                    if (_selectedFolder != null) {
                      _loadFolderDocuments(_selectedFolder!);
                    } else {
                      _loadFolders();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : _selectedFolder == null
                    ? _buildFoldersView()
                    : _buildDocumentsView(),
      ),
    );
  }

  Widget _buildErrorView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDark ? Colors.white54 : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              if (_selectedFolder != null) {
                _loadFolderDocuments(_selectedFolder!);
              } else {
                _loadFolders();
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: isDark ? Colors.white54 : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun dossier disponible',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _folders.length,
      itemBuilder: (context, index) {
        final folder = _folders[index];
        return _buildFolderCard(folder);
      },
    );
  }

  Widget _buildFolderCard(FolderModel folder) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.folder,
            color: Color(0xFF6366F1),
            size: 28,
          ),
        ),
        title: Text(
          folder.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: folder.description != null
            ? Text(
                folder.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Icon(
          Icons.chevron_right,
          color: isDark ? Colors.white54 : Colors.grey,
        ),
        onTap: () => _loadFolderDocuments(folder),
      ),
    );
  }

  Widget _buildDocumentsView() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoadingDocuments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: isDark ? Colors.white54 : Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun document dans ce dossier',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final document = _documents[index];
        return _buildDocumentCard(document);
      },
    );
  }

  Widget _buildDocumentCard(DocumentModel document) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getFileColor(document).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(document),
            color: _getFileColor(document),
            size: 28,
          ),
        ),
        title: Text(
          document.name,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          document.fileSizeFormatted,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.download,
          color: isDark ? Colors.white54 : const Color(0xFF6366F1),
        ),
        onTap: () => _openDocument(document),
      ),
    );
  }

  IconData _getFileIcon(DocumentModel document) {
    if (document.isPDF) return Icons.picture_as_pdf;
    if (document.isImage) return Icons.image;
    if (document.isDocument) return Icons.description;
    if (document.isSpreadsheet) return Icons.table_chart;
    if (document.isPresentation) return Icons.slideshow;
    return Icons.insert_drive_file;
  }

  Color _getFileColor(DocumentModel document) {
    if (document.isPDF) return Colors.red;
    if (document.isImage) return Colors.blue;
    if (document.isDocument) return const Color(0xFF6366F1);
    if (document.isSpreadsheet) return Colors.green;
    if (document.isPresentation) return Colors.orange;
    return Colors.grey;
  }
}
