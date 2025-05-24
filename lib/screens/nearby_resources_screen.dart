import 'package:flutter/material.dart';
import 'labour.dart';
import 'tractor.dart';

class NearbyResourcesScreen extends StatefulWidget {
  const NearbyResourcesScreen({super.key});

  @override
  State<NearbyResourcesScreen> createState() => _NearbyResourcesScreenState();
}

class _NearbyResourcesScreenState extends State<NearbyResourcesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Resources'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Labor',
            ),
            Tab(
              icon: Icon(Icons.agriculture),
              text: 'Tractors',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Labor Tab
          const WorkPricePage(),
          // Tractors Tab
          const TractorListPage(),
        ],
      ),
    );
  }
} 