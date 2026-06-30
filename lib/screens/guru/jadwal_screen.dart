import 'package:flutter/material.dart';
import 'prosem_tab.dart';
import 'rppm_tab.dart';
import 'modul_ajar_tab.dart';

class JadwalScreen extends StatefulWidget {
  final int? idGuru;
  final int? idKelas;
  final bool isReadOnly;
  const JadwalScreen({super.key, this.idGuru, this.idKelas, this.isReadOnly = false});

  @override
  State<JadwalScreen> createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color _primary = Color(0xFFC17B2F);
  static const Color _bg = Color(0xFFFDF8F3);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Rencana Pembelajaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
          tabs: const [
            Tab(text: 'Prosem'),
            Tab(text: 'RPPM (Mingguan)'),
            Tab(text: 'Modul Ajar (RPPH)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ProsemTab(idGuru: widget.idGuru, idKelas: widget.idKelas, isReadOnly: widget.isReadOnly),
          RppmTab(idGuru: widget.idGuru, idKelas: widget.idKelas, isReadOnly: widget.isReadOnly),
          ModulAjarTab(idGuru: widget.idGuru, idKelas: widget.idKelas, isReadOnly: widget.isReadOnly),
        ],
      ),
    );
  }
}

