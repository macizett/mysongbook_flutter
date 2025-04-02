import 'package:flutter/material.dart';
import 'package:github/github.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'Song.dart';
import 'Verse.dart';
import 'ViewModel.dart';

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

class UpdateProgressDialog extends StatefulWidget {
  final int total;
  final VoidCallback onCancel;

  const UpdateProgressDialog({
    Key? key,
    required this.total,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<UpdateProgressDialog> {
  int _current = 0;

  void updateProgress(int value) {
    setState(() => _current = value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aktualizacja modułów'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: _current / widget.total,
          ),
          const SizedBox(height: 16),
          Text('$_current/${widget.total}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('Anuluj'),
        ),
      ],
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

  static const Map<String, int> songbookIds = {
    'Pieśni Duchowe.json': 1,
    'Wędrowiec.json': 2,
    'Śpiewnik Młodzieżowy.json': 3,
    // Add more mappings as needed
  };

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadsPath = '${directory.path}/downloads';
    final dir = Directory(downloadsPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return downloadsPath;
  }

  Future<String?> _getFileHash(String path) async {
    try {
      final response = await github.getJSON(
        '/repos/$owner/$repository/contents/$path',
        convert: (json) => json as List<String>,
      );
      // Use null-aware operator to handle missing or null 'sha'
      return response[] as String?;
    } catch (e) {
      throw Exception('Failed to get file hash: $e');
    }
  }
  Future<Map<String, String>> _loadVersions() async {
    final versionsFile = File('${await _localPath}/versions.json');
    if (await versionsFile.exists()) {
      final content = await versionsFile.readAsString();
      return Map<String, String>.from(json.decode(content));
    }
    return {};
  }

  Future<void> _saveVersions(Map<String, String> versions) async {
    final versionsFile = File('${await _localPath}/versions.json');
    await versionsFile.writeAsString(json.encode(versions));
  }

  Future<List<GithubFile>> listFiles() async {
    try {
      final files = <GithubFile>[];

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

      return files;
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  Future<void> _parseAndSaveSongs(String jsonContent, int songbookId) async {
    final List<dynamic> songsJson = json.decode(jsonContent);
    final List<Song> songs = songsJson.map((songJson) => Song(
      id: songJson['id'] ?? 0,
      text: songJson['text'] ?? '',
      textNormalized: songJson['text']?.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '') ?? '',
      number: songJson['number'] ?? 0,
      title: songJson['title'] ?? '',
      songbook: songbookId,
      strophes: songJson['strophes'] ?? 0,
    )).toList();

    await ViewModel.insertAllSongs(songs);
  }

  Future<void> _parseAndSaveVerses(String jsonContent) async {
    final List<dynamic> versesJson = json.decode(jsonContent);
    final List<Verse> verses = versesJson.map((verseJson) => Verse(
      id: verseJson['id'] ?? 0,
      place: verseJson['place'] ?? '',
      text: verseJson['text'] ?? '',
    )).toList();

    await ViewModel.insertAllVerses(verses);
  }

  Future<void> downloadFile(GithubFile file) async {
    try {
      final versions = await _loadVersions();
      final currentHash = await _getFileHash(file.path);

      // Skip if version hasn't changed
      if (versions[file.path] == currentHash && await isFileDownloaded(file.name)) {
        return;
      }

      // Get songbook ID from the mapping
      final songbookId = songbookIds[file.name];
      if (songbookId == null) {
        throw Exception('Unknown songbook: ${file.name}');
      }

      // Download and parse JSON file
      final jsonResponse = await github.request(
        'GET',
        '/repos/$owner/$repository/contents/${file.path}',
        headers: {'Accept': 'application/vnd.github.v3.raw'},
      );

      if (jsonResponse.body is String) {
        await _parseAndSaveSongs(jsonResponse.body as String, songbookId);
      }

      // Save new version
      versions[file.path] = currentHash!;
      await _saveVersions(versions);

    } catch (e) {
      print('Error in downloadFile: $e');
      throw Exception('Failed to download and parse file: $e');
    }
  }

  Future<bool> isFileDownloaded(String fileName) async {
    try {
      final songbookId = songbookIds[fileName];
      if (songbookId == null) {
        return false;
      }

      final songs = ViewModel.getAllSongsBySongbook(songbookId);
      return songs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<void> downloadVersesFile(String languageCode) async {
    final jsonFileName = 'verses_$languageCode.json';

    try {
      // Try to get the current hash but handle null case
      String? currentHash;
      try {
        currentHash = await _getFileHash(jsonFileName);
      } catch (e) {
        print('Warning: Could not get hash for verses file: $e');
        // Continue without hash - will force download
      }

      final versions = await _loadVersions();

      // Skip if version hasn't changed and we have a hash
      if (currentHash != null && versions[jsonFileName] == currentHash) {
        return;
      }

      // Download the file
      final jsonResponse = await github.request(
        'GET',
        '/repos/$owner/$repository/contents/$jsonFileName',
        headers: {'Accept': 'application/vnd.github.v3.raw'},
      );

      await _parseAndSaveVerses(jsonResponse.body);
      print('Verses parsed');

      // Update version if we have a hash
      if (currentHash != null) {
        versions[jsonFileName] = currentHash;
        await _saveVersions(versions);
      }

    } catch (e) {
      print('Warning: Failed to download verses file: $e');
      // Don't throw here as verses are downloaded in background
    }
  }

  Future<void> deleteFile(String fileName) async {
    try {
      // Delete from Hive database
      final songbookId = int.tryParse(fileName.split('_')[1].split('.')[0]) ?? 0;
      final songs = ViewModel.getAllSongsBySongbook(songbookId);
      for (var song in songs) {
        await song.delete();
      }

      // Remove from versions
      final versions = await _loadVersions();
      versions.remove('$path/$fileName');
      await _saveVersions(versions);

    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  Future<List<GithubFile>> checkForUpdates(BuildContext context) async {
    try {
      final versions = await _loadVersions();
      final files = await listFiles();
      final updatedFiles = <GithubFile>[];

      for (var file in files) {
        if (await isFileDownloaded(file.name)) {
          final currentHash = await _getFileHash(file.path);
          if (versions[file.path] != currentHash) {
            updatedFiles.add(file);
          }
        }
      }

      if (updatedFiles.isNotEmpty) {
        final shouldUpdate = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Dostępne aktualizacje'),
            content: Text('Znaleziono ${updatedFiles.length} aktualizacji modułów. Czy chcesz je pobrać?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Anuluj'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Aktualizuj'),
              ),
            ],
          ),
        );

        if (shouldUpdate == true) {
          await _downloadUpdates(context, updatedFiles);
        }
      }

      return updatedFiles;
    } catch (e) {
      throw Exception('Failed to check for updates: $e');
    }
  }

  Future<void> _downloadUpdates(BuildContext context, List<GithubFile> files) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateProgressDialog(
        total: files.length,
        onCancel: () => Navigator.pop(context),
      ),
    );

    try {
      for (var i = 0; i < files.length; i++) {
        await downloadFile(files[i]);
        if (context.mounted) {
          (context.findAncestorStateOfType<_UpdateProgressDialogState>())
              ?.updateProgress(i + 1);
        }
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Moduły zostały zaktualizowane')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Błąd podczas aktualizacji modułów'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
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
      // First download verses file if not exists or needs update
      await _manager.downloadVersesFile(widget.languageCode);

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
      for (final file in _selectedFiles) {if (!file.isDownloaded) {
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
                  : '$_error',
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
                    width: 48.0,
                    child: Center(
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.green,
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