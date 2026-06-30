import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class GenericManagementScreen extends StatefulWidget {
  final String title;
  final String endpoint;
  final List<Map<String, dynamic>> mockData;
  final List<String> fields;
  final String entityName;

  const GenericManagementScreen({
    super.key,
    required this.title,
    required this.endpoint,
    required this.mockData,
    required this.fields,
    required this.entityName,
  });

  @override
  State<GenericManagementScreen> createState() =>
      _GenericManagementScreenState();
}

class _GenericManagementScreenState
    extends State<GenericManagementScreen> {
  List<dynamic> _items = [];
  bool _isLoading = true;
  bool _isConnected = false;
  int _mockIdCounter = 1000;

  Color get _primaryColor {
    switch (widget.entityName.toLowerCase()) {
      case 'anak':
        return Colors.orange;
      case 'kelas':
        return Colors.blue;
      case 'tahun ajaran':
        return Colors.purple;
      case 'aspek':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData get _entityIcon {
    switch (widget.entityName.toLowerCase()) {
      case 'anak':
        return Icons.child_care;
      case 'kelas':
        return Icons.class_;
      case 'tahun ajaran':
        return Icons.calendar_month;
      case 'aspek':
        return Icons.assignment;
      default:
        return Icons.folder;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    final result =
        await ApiService.fetchData(widget.endpoint, widget.mockData);

    if (result['status'] == 'success') {
      setState(() {
        _items = List<dynamic>.from(result['data']);
        _isConnected = result['source'] == 'server';
      });
    }

    setState(() => _isLoading = false);
  }

  String _fieldLabel(String field) {
    switch (field) {
      case 'nama_anak':
        return 'Nama Anak';
      case 'nama_kelas':
        return 'Nama Kelas';
      case 'nama_aspek':
        return 'Nama Aspek';
      case 'tahun':
        return 'Tahun';
      case 'status':
        return 'Status';
      case 'nisn':
        return 'NISN';
      case 'alamat':
        return 'Alamat';
      case 'jenis_kelamin':
        return 'Jenis Kelamin';
      default:
        return field.replaceAll('_', ' ').toUpperCase();
    }
  }

  void _showForm({Map<String, dynamic>? item}) {
    final isEdit = item != null;

    final controllers = {
      for (var field in widget.fields)
        field: TextEditingController(
          text: item?[field]?.toString() ?? '',
        ),
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor:
                          _primaryColor.withOpacity(0.1),
                      child: Icon(
                        isEdit ? Icons.edit : Icons.add,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isEdit
                          ? 'Edit ${widget.entityName}'
                          : 'Tambah ${widget.entityName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                ...widget.fields.map((field) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextField(
                      controller: controllers[field],
                      decoration: InputDecoration(
                        labelText: _fieldLabel(field),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                        prefixIcon: const Icon(Icons.edit),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(
                      isEdit ? 'Update Data' : 'Simpan Data',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      Map<String, dynamic> data = {
                        'action': isEdit ? 'update' : 'add',
                      };

                      if (isEdit) {
                        data['id'] = item['id'];
                      }

                      controllers.forEach((key, controller) {
                        data[key] = controller.text;
                      });

                      // OFFLINE MODE
                      if (!_isConnected) {
                        if (isEdit) {
                          final index = _items.indexWhere(
                            (e) => e['id'] == item['id'],
                          );

                          if (index != -1) {
                            setState(() {
                              _items[index] = {
                                ..._items[index],
                                ...data,
                              };
                            });
                          }
                        } else {
                          data['id'] = _mockIdCounter++;

                          setState(() {
                            _items.add(data);
                          });
                        }

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit
                                  ? 'Data berhasil diperbarui (offline)'
                                  : 'Data berhasil ditambahkan (offline)',
                            ),
                          ),
                        );

                        return;
                      }

                      // ONLINE MODE
                      final result = await ApiService.postData(
                        widget.endpoint,
                        data,
                      );

                      if (result['status'] == 'success') {
                        Navigator.pop(context);

                        _fetchData();

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message'] ??
                                  'Data berhasil disimpan',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message'] ??
                                  'Terjadi kesalahan',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    if (!_isConnected) {
      setState(() {
        _items.removeWhere((e) => e['id'] == item['id']);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil dihapus (offline)'),
        ),
      );

      return;
    }

    final result = await ApiService.postData(
      widget.endpoint,
      {
        'action': 'delete',
        'id': item['id'],
      },
    );

    if (result['status'] == 'success') {
      _fetchData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Data berhasil dihapus',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result['message'] ?? 'Gagal menghapus'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: Colors.blue.shade900,
        foregroundColor: Colors.white,
      ),

      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Icon(
                        _entityIcon,
                        size: 70,
                        color: _primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada data ${widget.entityName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                        margin:
                            const EdgeInsets.only(bottom: 14),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _primaryColor.withOpacity(0.1),
                            child: Icon(
                              _entityIcon,
                              color: _primaryColor,
                            ),
                          ),
                          title: Text(
                            item[widget.fields[0]]
                                    ?.toString() ??
                                '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: widget.fields.length > 1
                              ? Text(
                                  item[widget.fields[1]]
                                          ?.toString() ??
                                      '',
                                )
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _showForm(item: item),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _deleteItem(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        onPressed: () => _showForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
