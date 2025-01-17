import 'package:flutter/material.dart';
import 'package:frontend/common/token_manager.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/user_api/flight_api_server.dart';
import '../../../models/flight.dart';
import 'seat_selection_page.dart'; // 导入座位选择页面
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

class FlightResultsPage extends StatefulWidget {
  final String departureCode;
  final String arrivalCode;
  final String departureDate;

  const FlightResultsPage({
    required this.departureCode,
    required this.arrivalCode,
    required this.departureDate,
  });

  @override
  _FlightResultsPageState createState() => _FlightResultsPageState();
}

class _FlightResultsPageState extends State<FlightResultsPage>
    with SingleTickerProviderStateMixin {
  List<Flight> flights = [];
  Map<int, Map<String, dynamic>> flightPrices = {};
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _fetchFlights();
    _controller = AnimationController(
      duration: Duration(milliseconds: 150),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
    );
  }

  Future<void> _fetchFlights() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? token = TokenManager.getToken();
      if (token == null) throw Exception('用户未登录，请重新登录');

      flights = await FlightAPI().searchFlights(
        token,
        widget.departureCode,
        widget.arrivalCode,
        departureDate: widget.departureDate,
      );

      // 筛除起飞时间早于当前时间的航班
      DateTime now = DateTime.now();
      flights = flights.where((flight) {
        DateTime departureTime = DateTime.parse(flight.departureTime);
        return departureTime.isAfter(now);
      }).toList();

      for (var flight in flights) {
        final priceData =
            await FlightAPI().fetchMinPriceWithSeatType(token, flight.flightId);
        flightPrices[flight.flightId] = priceData ??
            {
              "min_price": 0.0,
              "seat_type": "未知舱位",
            };
      }
    } catch (e) {
      setState(() {
        _errorMessage = "获取航班数据失败，请稍后重试";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(String dateTimeStr) {
    return DateFormat('HH:mm').format(DateTime.parse(dateTimeStr));
  }

  bool _isNextDay(String start, String end) {
    final startTime = DateTime.parse(start);
    final endTime = DateTime.parse(end);
    return endTime.day > startTime.day;
  }

  String _calculateDuration(String start, String end) {
    final startTime = DateTime.parse(start);
    final endTime = DateTime.parse(end);
    final duration = endTime.difference(startTime);
    return "${duration.inHours}小时 ${duration.inMinutes % 60}分钟";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "航班列表 - ${widget.departureDate}",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
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
        elevation: 5,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : _errorMessage != null
              ? _buildErrorWidget()
              : flights.isEmpty
                  ? _buildNoFlightsWidget()
                  : ListView.builder(
                      padding: EdgeInsets.all(12),
                      itemCount: flights.length,
                      itemBuilder: (context, index) {
                        final flight = flights[index];
                        final priceData = flightPrices[flight.flightId];
                        final price = priceData?['min_price'] ?? 0.0;
                        final seatType =
                            _convertSeatType(priceData?['seat_type'] ?? '未知舱位');

                        return ScaleTransition(
                          scale: _controller,
                          child: GestureDetector(
                            onTapDown: (_) => _controller.forward(),
                            onTapUp: (_) => _controller.reverse(),
                            child: _buildFlightCard(flight, price, seatType),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Text(
        _errorMessage!,
        style: TextStyle(color: Colors.redAccent, fontSize: 18),
      ),
    );
  }

  Widget _buildNoFlightsWidget() {
    return Center(
      child: Text(
        "没有找到符合条件的航班",
        style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildFlightCard(Flight flight, double price, String seatType) {
    final isNextDay = _isNextDay(flight.departureTime, flight.arrivalTime);
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeSection(flight.departureTime, flight.departureAirport,
                    isNextDay: false),
                Icon(Icons.flight, color: Colors.teal, size: 40),
                _buildTimeSection(flight.arrivalTime, flight.arrivalAirport,
                    isNextDay: isNextDay),
              ],
            ),
            Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    "飞行时长: ${_calculateDuration(flight.departureTime, flight.arrivalTime)}"),
                Text("航班号: ${flight.flightId}"),
                Text("机型: ${flight.planeModel}"),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("￥${price.toStringAsFixed(0)} 起",
                    style: TextStyle(
                        color: Colors.orange,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Text(seatType,
                    style:
                        TextStyle(fontSize: 16, color: Colors.grey.shade700)),
              ],
            ),
            SizedBox(height: 20), // 增加间隔
            _buildActionButtons(flight), // 新增按钮组
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Flight flight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => _navigateToSeatSelection(flight), // 去机场按钮的功能
          child: Text(
            "选舱位",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.teal, // 按钮背景颜色
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)), // 按钮圆角
          ),
        ),

        SizedBox(width: 20),
        // 增加间隔
        TextButton(
          onPressed: () => _navigateToAirport(flight), // 去机场按钮的功能
          child: Text(
            "去机场",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.teal, // 按钮背景颜色
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)), // 按钮圆角
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection(String time, String airport,
      {bool isNextDay = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(_formatTime(time),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            if (isNextDay)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text("+1", style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
        Text(airport, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  void _navigateToSeatSelection(Flight flight) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionPage(
          flightId: flight.flightId,
          departureTime: flight.departureTime,
          arrivalTime: flight.arrivalTime,
          departureAirport: flight.departureAirport,
          arrivalAirport: flight.arrivalAirport,
          planeModel: flight.planeModel,
        ),
      ),
    );
  }

void _navigateToAirport(Flight flight) async {
  // 确保 departureAirport 不是 null
  if ( flight.departureAirport.isEmpty) {
    throw '出发机场信息缺失，无法导航到机场';
  }

  // URL 编码处理中文
  String queryUrl = 'https://ditu.amap.com/search??query='+Uri.encodeComponent(flight.departureAirport);

  // 检查 URL 格式并尝试打开
  final Uri url = Uri.parse(queryUrl);
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    throw '无法打开地图：$queryUrl';
  }
}

  // void _navigateToAirport(Flight flight) {
  //   // 确保 departureAirport 不是 null
  //   if (flight.departureAirport.isEmpty) {
  //     throw '出发机场信息缺失，无法导航到机场';
  //   }

  //   // 编码机场名称以确保URL的有效性
  //   String encodedAirportName = Uri.encodeComponent(flight.departureAirport);

  //   // 构建高德地图的URL
  //   String mapUrl = 'https://ditu.amap.com/search?query=$encodedAirportName';

  //   // 打开WebView页面
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => AirportMapPage(
  //           apiKey: '1202df2f381f322e9ddaec6d876791f1', mapUrl: mapUrl),
  //     ),
  //   );
  // }

  String _convertSeatType(String seatType) {
    switch (seatType) {
      case 'economy':
        return "经济舱";
      case 'business':
        return "商务舱";
      case 'first_class':
        return "头等舱";
      default:
        return "未知舱位";
    }
  }
}

class AirportMapPage extends StatelessWidget {
  final String apiKey;
  final String mapUrl;

  const AirportMapPage({required this.apiKey, required this.mapUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('机场地图'),
      ),
      body: WebView(
        initialUrl: mapUrl,
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          // 这里可以添加更多的WebView配置和事件处理
        },
      ),
    );
  }
}
