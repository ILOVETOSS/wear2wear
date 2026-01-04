import 'package:flutter/material.dart';
import 'dart:io';
import '../data/mock_data.dart';

class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("MATCHES"),
        backgroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF4D4D),
          tabs: const [Tab(text: "보낸 요청"), Tab(text: "받은 요청")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(matchedItems, "보낸 요청이 없습니다."),
          _buildList([], "받은 요청이 없습니다."),
        ],
      ),
    );
  }

  Widget _buildList(List list, String msg) {
    return list.isEmpty
        ? Center(child: Text(msg, style: const TextStyle(color: Colors.white54)))
        : ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: item.isLocal
                ? Image.file(File(item.imageUrl), width: 50, height: 50, fit: BoxFit.cover)
                : Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
          ),
          title: Text(item.brand),
          subtitle: Text(item.title),
          trailing: const Text("대기중", style: TextStyle(color: Color(0xFFFF4D4D))),
        );
      },
    );
  }
}