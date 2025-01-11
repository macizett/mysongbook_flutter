import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback onRefresh;

  const ErrorDisplay({
    Key? key,
    required this.message,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Odśwież'),
          ),
        ],
      ),
    );
  }
}

class GithubFilesManager {
  final GitHub github;
  final String owner;
  final String repository;
  final String path;

  GithubFilesManager({
    required String token,
    required this.owner,
    required this.repository,
    this.path = '',
  }) : github = GitHub(auth: Authentication.withToken(token));

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadsPath = '${directory.path}/downloads';
    final dir = Directory(downloadsPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return downloadsPath;
  }

  Future<List<GithubFile>> listFiles() async {
    try {
      final files = <GithubFile>[];

      try {
        final response = await github.getJSON(
          '/repos/$owner/$repository/contents/$path',
          convert: (json) {
            if (json is List) {
              return json.map((item) => item as Map<String, dynamic>).toList();
            }
            return [json as Map<String, dynamic>];
          },
        );

        for (final item in response) {
          if (item['type'] == 'file' && item['name'].toString().endsWith('.json')) {
            final file = GithubFile(
              name: item['name'] as String? ?? '',
              downloadUrl: item['download_url'] as String? ?? '',
              path: item['path'] as String? ?? '',
            );
            files.add(file);
          }
        }
      } catch (e) {
        throw Exception('Failed to list files: $e');
      }
      return files;
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  Future<void> downloadFile(GithubFile file) async {
    try {
      // Download JSON file
      final jsonResponse = await github.request(
        'GET',
        '/repos/$owner/$repository/contents/${file.path}',
        headers: {'Accept': 'application/vnd.github.v3.raw'},
      );

      final localPath = await _localPath;
      final jsonFilePath = '$localPath/${file.name}';
      final File jsonFile = File(jsonFilePath);

      if (jsonResponse.body is String) {
        await jsonFile.writeAsString(jsonResponse.body as String);
      } else if (jsonResponse.body is List<int>) {
        await jsonFile.writeAsBytes(jsonResponse.body as List<int>);
      }

      // Download corresponding PNG file
      final pngFileName = file.name.replaceAll('.json', '.png');
      final pngPath = file.path.replaceAll('.json', '.png');

      try {
        final pngResponse = await github.request(
          'GET',
          '/repos/$owner/$repository/contents/$pngPath',
          headers: {'Accept': 'application/vnd.github.v3.raw'},
        );

        final pngFilePath = '$localPath/$pngFileName';
        final File pngFile = File(pngFilePath);

        if (pngResponse.body is List<int>) {
          await pngFile.writeAsBytes(pngResponse.body as List<int>);
        }
      } catch (e) {
        print('Warning: PNG file not found or failed to download: $e');
      }

    } catch (e) {
      throw Exception('Failed to download files: $e');
    }
  }

  Future<bool> isFileDownloaded(String fileName) async {
    final localPath = await _localPath;
    final jsonPath = '$localPath/$fileName';
    final pngPath = '$localPath/${fileName.replaceAll('.json', '.png')}';

    // Check both JSON and PNG files
    final jsonExists = await File(jsonPath).exists();
    final pngExists = await File(pngPath).exists();

    return jsonExists && pngExists;
  }

  Future<void> deleteFile(String fileName) async {
    final localPath = await _localPath;
    final jsonPath = '$localPath/$fileName';
    final pngPath = '$localPath/${fileName.replaceAll('.json', '.png')}';

    // Delete both JSON and PNG files
    final jsonFile = File(jsonPath);
    final pngFile = File(pngPath);

    if (await jsonFile.exists()) {
      await jsonFile.delete();
    }
    if (await pngFile.exists()) {
      await pngFile.delete();
    }
  }

  Future<void> downloadVersesFile(String languageCode) async {
    final jsonFileName = 'verses_$languageCode.json';
    final pngFileName = 'verses_$languageCode.png';

    try {
      // Download JSON file
      final jsonResponse = await github.request(
        'GET',
        '/repos/$owner/$repository/contents/$jsonFileName',
        headers: {'Accept': 'application/vnd.github.v3.raw'},
      );

      final localPath = await _localPath;
      final jsonFilePath = '$localPath/$jsonFileName';
      final File jsonFile = File(jsonFilePath);

      if (jsonResponse.body is String) {
        await jsonFile.writeAsString(jsonResponse.body as String);
      } else if (jsonResponse.body is List<int>) {
        await jsonFile.writeAsBytes(jsonResponse.body as List<int>);
      }

      // Download PNG file
      try {
        final pngResponse = await github.request(
          'GET',
          '/repos/$owner/$repository/contents/$pngFileName',
          headers: {'Accept': 'application/vnd.github.v3.raw'},
        );

        final pngFilePath = '$localPath/$pngFileName';
        final File pngFile = File(pngFilePath);

        if (pngResponse.body is List<int>) {
          await pngFile.writeAsBytes(pngResponse.body as List<int>);
        }
      } catch (e) {
        print('Warning: Verses PNG file not found or failed to download: $e');
      }

    } catch (e) {
      throw Exception('Failed to download verses files: $e');
    }
  }
}

class GithubFile {
  final String name;
  final String downloadUrl;
  final String path;
  bool isDownloaded;

  GithubFile({
    required this.name,
    required this.downloadUrl,
    required this.path,
    this.isDownloaded = false,
  });
}

class GithubFilesScreen extends StatefulWidget {
  final String languageCode;

  const GithubFilesScreen({
    Key? key,
    required this.languageCode,
  }) : super(key: key);

  @override
  State<GithubFilesScreen> createState() => _GithubFilesScreenState();
}

class _GithubFilesScreenState extends State<GithubFilesScreen> {
  late GithubFilesManager _manager;
  List<GithubFile> _files = [];
  Set<GithubFile> _selectedFiles = {};
  bool _isLoading = false;
  String _error = '';

  bool get _isNetworkError {
    return _error.toLowerCase().contains('failed host lookup') ||
        _error.toLowerCase().contains('socket exception') ||
        _error.toLowerCase().contains('connection refused') ||
        _error.toLowerCase().contains('network is unreachable');
  }

  @override
  void initState() {
    super.initState();
    _manager = GithubFilesManager(
      token: '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',
      owner: 'mySongbook-data',
      repository: 'mysongbook_data',
      path: 'songbooks',
    );
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // First download verses file if not exists
      if (!await _manager.isFileDownloaded('verses_${widget.languageCode}.json')) {
        await _manager.downloadVersesFile(widget.languageCode);
      }
      // Then load songbook files
      await _loadFiles();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFiles() async {
    try {
      final files = await _manager.listFiles();

      // Check which files are already downloaded
      for (var file in files) {
        file.isDownloaded = await _manager.isFileDownloaded(file.name);
      }

      setState(() {
        _files = files;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _downloadSelectedFiles() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      for (final file in _selectedFiles) {
        if (!file.isDownloaded) {
          await _manager.downloadFile(file);
          file.isDownloaded = true;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moduły zostały pobrane pomyślnie')),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      if (_isNetworkError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie można pobrać modułów. Sprawdź połączenie z internetem'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        if (_error.isEmpty) {
          _selectedFiles.clear();
        }
      });
    }
  }

  void _deleteModule(GithubFile file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Usuń moduł'),
          content: Text('Czy na pewno chcesz usunąć moduł "${file.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () async {
                await _manager.deleteFile(file.name);
                setState(() {
                  file.isDownloaded = false;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Moduł został usunięty')),
                );
              },
              child: const Text('Usuń', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dostępne moduły śpiewników'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                ? ErrorDisplay(
              message: _isNetworkError
                  ? 'Sprawdź połączenie z internetem'
                  : 'Error: $_error',
              onRefresh: _initialize,
            )
                : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final isSelected = _selectedFiles.contains(file);

                return ListTile(
                  title: Text(file.name),
                  subtitle: file.isDownloaded
                      ? const Text('Pobrany',
                      style: TextStyle(color: Colors.green))
                      : null,
                  leading: !file.isDownloaded
                      ? Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value ?? false) {
                          _selectedFiles.add(file);
                        } else {
                          _selectedFiles.remove(file);
                        }
                      });
                    },
                  )
                      : const SizedBox(
                    width: 48.0, // This matches the default checkbox width
                    child: Center(
                      child: Icon(
                          Icons.check_circle,
                          color: Colors.green
                      ),
                    ),
                  ),
                  trailing: file.isDownloaded
                      ? IconButton(
                    icon: const Icon(Icons.delete,
                        color: Colors.red),
                    onPressed: () => _deleteModule(file),
                  )
                      : null,
                );
              },
            ),
          ),
          if (_selectedFiles.isNotEmpty && _error.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                icon: const Icon(Icons.download, size: 28),
                label: const Text(
                  'Pobierz wybrane moduły',
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: _downloadSelectedFiles,
              ),
            ),
        ],
      ),
    );
  }
}