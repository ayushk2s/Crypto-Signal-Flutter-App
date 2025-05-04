import 'package:http/http.dart' as http;
import 'dart:convert';

class SpotTicker {
  // Fetch all 24hr ticker data from MEXC
  Future<List<Map<String, dynamic>>?> fetchAllTickers() async {
    const url = 'https://api.mexc.com/api/v3/ticker/24hr';
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
      'Accept': 'application/json',
      'Connection': 'keep-alive',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          return data.cast<Map<String, dynamic>>();
        }
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching ticker data: $e');
    }
    return null;
  }

  // Filter ticker data by selected symbols and return desired fields
  List<Map<String, dynamic>> getSymbolStats(List<Map<String, dynamic>> allData, List<String> symbols) {
    // Create a map from all data for faster lookup
    final dataMap = {for (var item in allData) item['symbol']: item};

    // Rebuild result in the order of the input symbols
    return symbols
        .where((symbol) => dataMap.containsKey(symbol))
        .map((symbol) {
      final item = dataMap[symbol];
      double lastPrice = double.tryParse(item!['lastPrice'] ?? '0') ?? 0.0;
      double volume = double.tryParse(item['volume'] ?? '0') ?? 0.0;
      double priceChange = double.tryParse(item['priceChange'] ?? '0') ?? 0.0;
      double priceChangePercent = double.tryParse(item['priceChangePercent'] ?? '0') ?? 0.0;

      return {
        'symbol': symbol,
        'lastPrice': lastPrice,
        'newVolume': volume * lastPrice,
        'priceChange': priceChange,
        'priceChangePercent': priceChangePercent * 100
      };
    })
        .toList();
  }

}


void main() async {
  final spotTicker = SpotTicker();

  // Desired symbols to track
  List<String> mySymbols = ['SOLUSDT', 'ETHUSDT', 'BTCUSDT'];

  // Fetch all data from MEXC
  final allData = await spotTicker.fetchAllTickers();

  if (allData != null) {
    // Get stats for selected symbols
    final result = spotTicker.getSymbolStats(allData, mySymbols);
    print(result);
  } else {
    print("Failed to fetch data.");
  }
}
