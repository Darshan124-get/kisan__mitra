import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Live Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({Key? key}) : super(key: key);

  @override
  _WeatherHomePageState createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final String apiKey = '9136e8596098a10b3106e2eae0fba465';
  Map<String, dynamic>? currentWeather;
  List<dynamic>? forecast;
  bool isLoading = true;
  String error = '';
  String background = 'clear';
  Position? currentPosition;
  DateTime? lastUpdated;

  @override
  void initState() {
    super.initState();
    fetchLocationAndWeather();
  }

  Future<void> fetchLocationAndWeather() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          error = "Please enable location services to get weather data";
          isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          setState(() {
            error = "Location permission is required for weather data";
            isLoading = false;
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        currentPosition = position;
      });

      // Fetch current weather
      final currentWeatherResponse = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric'));

      if (currentWeatherResponse.statusCode != 200) {
        throw Exception('Failed to load current weather');
      }

      // Fetch 5-day forecast
      final forecastResponse = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric'));

      if (forecastResponse.statusCode != 200) {
        throw Exception('Failed to load forecast');
      }

      setState(() {
        currentWeather = json.decode(currentWeatherResponse.body);
        forecast = json.decode(forecastResponse.body)['list'];
        isLoading = false;
        lastUpdated = DateTime.now();
        background = getBackground(currentWeather!['weather'][0]['main']);
      });
    } catch (e) {
      setState(() {
        error = "Failed to get weather data: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  String getBackground(String weatherMain) {
    switch (weatherMain.toLowerCase()) {
      case 'rain':
      case 'thunderstorm':
      case 'drizzle':
        return 'rainy';
      case 'clouds':
        return 'cloudy';
      case 'snow':
        return 'snowy';
      case 'clear':
        return 'clear';
      default:
        return 'clear';
    }
  }

  bool willRain() {
    if (forecast == null) return false;
    return forecast!.take(5).any((entry) {
      final main = entry['weather'][0]['main'].toString().toLowerCase();
      return main.contains('rain') ||
          main.contains('thunderstorm') ||
          main.contains('drizzle');
    });
  }

  List<dynamic> getTomorrowForecast() {
    if (forecast == null) return [];
    final now = DateTime.now();
    final tomorrow = now.add(Duration(days: 1));
    return forecast!
        .where((item) {
          final itemDate = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          return itemDate.day == tomorrow.day;
        })
        .toList();
  }

  List<dynamic> getHourlyForecast() {
    if (forecast == null) return [];
    return forecast!.take(8).toList();
  }

  Color getPrimaryColor() {
    switch (background) {
      case 'rainy':
        return Colors.indigo;
      case 'cloudy':
        return Colors.blueGrey;
      case 'snowy':
        return Colors.lightBlue;
      default:
        return Colors.blue;
    }
  }

  String getWeatherIcon(String main) {
    switch (main.toLowerCase()) {
      case 'clouds':
        return 'assets/cloudy.svg';
      case 'rain':
        return 'assets/rain.svg';
      case 'thunderstorm':
        return 'assets/thunder.svg';
      case 'drizzle':
        return 'assets/drizzle.svg';
      case 'snow':
        return 'assets/snow.svg';
      case 'clear':
        return 'assets/sunny.svg';
      default:
        return 'assets/partly_cloudy.svg';
    }
  }

  Widget _buildCurrentWeather() {
    final temp = currentWeather!['main']['temp'].round();
    final feelsLike = currentWeather!['main']['feels_like'].round();
    final humidity = currentWeather!['main']['humidity'];
    final windSpeed = (currentWeather!['wind']['speed'] * 3.6).round();
    final weatherMain = currentWeather!['weather'][0]['main'];
    final description = currentWeather!['weather'][0]['description'];
    final city = currentWeather!['name'];
    final country = currentWeather!['sys']['country'] ?? '';

    return Column(
      children: [
        Text(
          '$city, $country',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          DateFormat('EEEE, MMMM d').format(DateTime.now()),
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$temp',
              style: TextStyle(
                fontSize: 80,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
            Text(
              '°C',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w300,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              getWeatherIcon(weatherMain),
              width: 40,
              height: 40,
              color: Colors.white,
            ),
            SizedBox(width: 8),
            Text(
              description.toString().toUpperCase(),
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          'Feels like $feelsLike°C',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail('Humidity', '$humidity%', Icons.water_drop),
              _buildWeatherDetail('Wind', '${windSpeed}km/h', Icons.air),
              _buildWeatherDetail(
                  'Pressure', '${currentWeather!['main']['pressure']}hPa', Icons.speed),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDetail(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    final hourly = getHourlyForecast();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'HOURLY FORECAST',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: hourly.length,
            itemBuilder: (context, index) {
              final item = hourly[index];
              final time = DateFormat('ha').format(
                  DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000));
              final temp = item['main']['temp'].round();
              final icon = item['weather'][0]['main'];

              return Container(
                width: 80,
                margin: EdgeInsets.symmetric(horizontal: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    SvgPicture.asset(
                      getWeatherIcon(icon),
                      width: 30,
                      height: 30,
                      color: Colors.white,
                    ),
                    Text(
                      '$temp°C',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyForecast() {
    final daily = getTomorrowForecast();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'TOMORROW\'S FORECAST',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            children: daily.map((item) {
              final time = DateFormat('ha').format(
                  DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000));
              final temp = item['main']['temp'].round();
              final icon = item['weather'][0]['main'];
              final description = item['weather'][0]['description'];

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        time,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            getWeatherIcon(icon),
                            width: 24,
                            height: 24,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              description.toString().toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        '$temp°C',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRainWarning() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Rain expected in the next few hours. Don't forget your umbrella!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: getPrimaryColor(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Live Weather',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (lastUpdated != null)
            Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Center(
                child: Text(
                  'Updated: ${DateFormat('h:mm a').format(lastUpdated!)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchLocationAndWeather,
          ),
        ],
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Fetching weather data...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      )
          : error.isNotEmpty
          ? Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 48),
              SizedBox(height: 20),
              Text(
                error,
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: getPrimaryColor(),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
                onPressed: fetchLocationAndWeather,
                child: Text('Try Again'),
              ),
            ],
          ),
        ),
      )
          : currentWeather == null
          ? Center(
        child: Text(
          'No weather data available',
          style: TextStyle(color: Colors.white),
        ),
      )
          : Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    getPrimaryColor().withOpacity(0.8),
                    getPrimaryColor().withOpacity(0.4),
                    getPrimaryColor(),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: Colors.white,
              backgroundColor: getPrimaryColor(),
              onRefresh: () => fetchLocationAndWeather(),
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    _buildCurrentWeather(),
                    SizedBox(height: 24),
                    if (willRain()) _buildRainWarning(),
                    SizedBox(height: 16),
                    _buildHourlyForecast(),
                    SizedBox(height: 16),
                    _buildDailyForecast(),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}