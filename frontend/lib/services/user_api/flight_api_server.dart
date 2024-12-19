import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/flight.dart';
import '../../models/ticket.dart';
import '../../models/order.dart';

class FlightAPI {
  final String apiUrl = "http://localhost:8000/user/flight";
  // final String apiUrl = "http://159.75.132.182:8000/user/flight";

  // 获取所有城市列表
  Future<List<dynamic>> fetchCities(String token, {String? query}) async {
    try {
      final response = await http.get(
        Uri.parse(
            query != null ? "$apiUrl/city/?query=$query" : "$apiUrl/city/"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody);
      } else {
        throw Exception("Failed to load cities: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching cities: $e");
    }
  }

  // 根据城市外码查询航班
  Future<List<Flight>> searchFlights(
      String token, String departureCode, String arrivalCode,
      {String? departureDate}) async {
    try {
      String url =
          "$apiUrl/search/?departure_city_code=$departureCode&arrival_city_code=$arrivalCode";
      if (departureDate != null) {
        url += "&departure_date=$departureDate";
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> data = json.decode(decodedBody);
        return data.map((json) => Flight.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        // 检查后端返回的 message
        final Map<String, dynamic> errorData = json.decode(response.body);
        if (errorData['message'] ==
            "No flights found for the provided city codes and date.") {
          // 返回空航班列表
          return [];
        } else {
          // 其他404错误抛出异常
          throw Exception(errorData['message']);
        }
      } else {
        // 其他状态码抛出统一错误
        throw Exception("Failed to search flights: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error searching flights: $e");
    }
  }

  Future<Map<String, dynamic>?> fetchMinPriceWithSeatType(
      String token, int flightId) async {
    final response = await http.get(
      Uri.parse("$apiUrl/ticket/min_price/$flightId/"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Token $token',
      },
    );

    if (response.statusCode == 200) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = json.decode(decodedBody);
      return {
        "min_price": data['min_price'],
        "seat_type": data['seat_type'],
      };
    } else if (response.statusCode == 404) {
      final decodedBody = utf8.decode(response.bodyBytes);
      final data = json.decode(decodedBody);
      return null; // 未找到票价
    } else {
      throw Exception("Failed to fetch minimum ticket price and seat type");
    }
  }

  // 获取航班的所有机票信息
  Future<List<Ticket>> fetchFlightTickets(String token, int flightId) async {
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/ticket/$flightId/"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> data = json.decode(decodedBody);
        return data.map((json) => Ticket.fromJson(json)).toList();
      } else {
        throw Exception(
            "Failed to fetch flight tickets: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching flight tickets: $e");
    }
  }

  // 创建订单
  Future<Order> purchaseTicket(
      String token, int passengerId, int ticketId) async {
    try {
      final response = await http.post(
        Uri.parse("$apiUrl/order/purchase/"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({
          'passenger_id': passengerId,
          'ticket_id': ticketId,
        }),
      );

      if (response.statusCode == 201) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return Order.fromJson(json.decode(decodedBody));
      } else {
        throw Exception("Failed to purchase ticket: ${response.statusCode}");
      }
    } catch (e) {
      print(e);
      throw Exception("Error purchasing ticket: $e");
    }
  }

  // 确认订单
  Future<void> confirmOrder(String token, int orderId) async {
    try {
      final response = await http.post(
        Uri.parse("$apiUrl/order/confirm/$orderId/"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );
      if (response.statusCode != 200) {
        throw Exception("Failed to confirm order: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error confirming order: $e");
    }
  }

  // 获取用户的所有订单
  Future<List<Order>> fetchUserOrders(String token, {String? status}) async {
    try {
      final response = await http.get(
        Uri.parse(status != null
            ? "$apiUrl/order/list/?status=$status"
            : "$apiUrl/order/list/"),
        headers: {
          'Authorization': 'Token $token',
        },
      );
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> data = json.decode(decodedBody);
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception("Failed to fetch user orders: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching user orders: $e");
    }
  }

  // 获取订单详情
  Future<Order> fetchOrderDetail(String token, int orderId) async {
    try {
      final response = await http.get(
        Uri.parse("$apiUrl/order/detail/$orderId/"),
        headers: {
          'Authorization': 'Token $token',
        },
      );
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return Order.fromJson(json.decode(decodedBody));
      } else {
        throw Exception("Failed to fetch order detail: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching order detail: $e");
    }
  }

  // 取消订单
  Future<void> cancelOrder(String token, int orderId) async {
    try {
      final response = await http.post(
        Uri.parse("$apiUrl/order/cancel/$orderId/"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        // 提示取消成功
        print("Order canceled successfully: $orderId");
      } else {
        throw Exception("Failed to cancel order: ${response.statusCode}");
      }
    } catch (e) {
      print("Error canceling order: $e");
      throw Exception("Error canceling order: $e");
    }
  }
}
