import 'package:flutter/material.dart';
import 'package:frontend/services/user_api/level_api_server.dart';

class LevelPage extends StatefulWidget {
  @override
  _LevelPageState createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> {
  final LevelAPI _levelAPI = LevelAPI();
  Map<String, dynamic>? _currentLevel; // 当前等级数据
  Map<String, dynamic>? _nextLevel; // 下一个等级数据
  bool _isLoading = true; // 加载状态
  String? _errorMessage; // 错误信息

  @override
  void initState() {
    super.initState();
    _fetchLevelData();
  }

  Future<void> _fetchLevelData() async {
    setState(() => _isLoading = true);
    try {
      final levelData = await _levelAPI.getUserLevel();
      final nextLevelData = await _levelAPI.getNextLevel();

      print("Current Level Data: $levelData"); // 调试用
      print("Next Level Data: $nextLevelData");

      setState(() {
        _currentLevel = levelData['level']; // 只取 level 数据
        _nextLevel = nextLevelData['next_level'] ?? null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "加载失败: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: Text("我的等级"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!, style: TextStyle(fontSize: 18)))
              : _buildLevelContent(),
    );
  }

  Widget _buildLevelContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCurrentLevelCard(),
          SizedBox(height: 20),
          _buildNextLevelCard(),
        ],
      ),
    );
  }

  // 当前等级卡片
  Widget _buildCurrentLevelCard() {
    final levelName = _currentLevel?['level_name'] ?? '未知';
    final userMiles = _currentLevel?['require_miles']?.toString() ?? '0';
    final userTickets = _currentLevel?['require_tickets']?.toString() ?? '0';

    return _buildGradientCard(
      title: "当前会员等级",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("等级名称", levelName),
          _buildInfoRow("当前里程", "$userMiles 公里"),
          _buildInfoRow("购票次数", "$userTickets 次"),
          Divider(height: 20, color: Colors.teal),
          _buildSectionTitle("等级权益"),
          Text(
            _currentLevel?['privileges'] ?? "暂无等级权益",
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // 下一个等级卡片
  Widget _buildNextLevelCard() {
    if (_nextLevel == null) {
      return _buildGradientCard(
        title: "下一个会员等级",
        content: Center(
          child: Text(
            "您已达到最高等级，继续保持！",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final nextLevelName = _nextLevel?['level_name']?.toString() ?? '未知';
    final milesGap = _nextLevel?['require_miles']?.toString() ?? '0';
    final ticketsGap = _nextLevel?['require_tickets']?.toString() ?? '0';
    final privileges = _nextLevel?['privileges'] ?? "暂无相关权益";

    return _buildGradientCard(
      title: "下一个会员等级",
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow("等级名称", nextLevelName),
          _buildInfoRow("里程差距", "$milesGap 公里"),
          _buildInfoRow("购票次数差距", "$ticketsGap 次"),
          Divider(height: 20, color: Colors.teal),
          _buildSectionTitle("预览等级权益"),
          Text(
            privileges,
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  // 封装卡片
  Widget _buildGradientCard({required String title, required Widget content}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade100, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
            SizedBox(height: 10),
            content,
          ],
        ),
      ),
    );
  }

  // 信息行
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.black54)),
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 小标题
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
      ),
    );
  }
}
