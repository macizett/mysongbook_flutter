import 'package:flutter/material.dart';
import 'package:github/github.dart';

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
          if (item['type'] == 'file') {
            files.add(GithubFile(
              name: item['name'] as String? ?? '',
              downloadUrl: item['download_url'] as String? ?? '',
              path: item['path'] as String? ?? '',
            ));
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

  Future<String> downloadFile(GithubFile file) async {
    try {
      final response = await github.request(
        'GET',
        '/repos/$owner/$repository/contents/${file.path}',
        headers: {'Accept': 'application/vnd.github.v3.raw'},
      );

      // Return the raw content as a string
      return response.body.toString();
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }
}

class GithubFile {
  final String name;
  final String downloadUrl;
  final String path;

  GithubFile({
    required this.name,
    required this.downloadUrl,
    required this.path,
  });
}

class GithubFilesScreen extends StatefulWidget {
  const GithubFilesScreen({Key? key}) : super(key: key);

  @override
  State<GithubFilesScreen> createState() => _GithubFilesScreenState();
}

class _GithubFilesScreenState extends State<GithubFilesScreen> {
  late GithubFilesManager _manager;
  List<GithubFile> _files = [];
  Set<GithubFile> _selectedFiles = {};
  bool _isLoading = false;
  String _error = '';
  final Map<String, String> _downloadedContent = {};

  @override
  void initState() {
    super.initState();
    _manager = GithubFilesManager(
      token: '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',
      owner: 'mySongbook-data',
      repository: 'mysongbook_data',
      path: 'songbooks',
    );
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final files = await _manager.listFiles();
      setState(() {
        _files = files;
      });
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

  Future<void> _downloadSelectedFiles() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      for (final file in _selectedFiles) {
        final content = await _manager.downloadFile(file);
        _downloadedContent[file.name] = content;
      }

      // Save to SharedPreferences or handle the content as needed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Files downloaded successfully!')),
      );
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
                ? Center(child: Text('Error: $_error'))
                : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                final isSelected = _selectedFiles.contains(file);
                final isDownloaded = _downloadedContent.containsKey(file.name);

                return ListTile(
                  title: Text(file.name),
                  subtitle: isDownloaded
                      ? const Text(
                      'Downloaded', style: TextStyle(color: Colors.green))
                      : null,
                  leading: Checkbox(
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
                  ),
                );
              },
            ),
          ),
          if (_selectedFiles.isNotEmpty)
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