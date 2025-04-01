import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'dart:ui';
import 'search_screen.dart';
import 'package:firebase_database/firebase_database.dart';

// Initialize database monitoring in main() function
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // OneSignal initialization
  OneSignal.initialize("4d56fe0b-b1a7-4f4b-b6d6-6d5c4829f746");
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.Notifications.requestPermission(true);
  OneSignal.User.addTagWithKey("topic", "all");

  // Initialize database monitoring service
  DatabaseMonitoringService().initialize();

  runApp(const MyApp());
}

// Create a service class to handle database monitoring
class DatabaseMonitoringService {
  // Singleton pattern
  static final DatabaseMonitoringService _instance =
      DatabaseMonitoringService._internal();
  factory DatabaseMonitoringService() => _instance;
  DatabaseMonitoringService._internal();

  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;

    final databaseRef = FirebaseDatabase.instance
        .ref('/yourDataPath'); // Replace with your actual Realtime DB path

    // Listen for changes in the database
    databaseRef.onChildChanged.listen((event) {
      _handleDatabaseEvent(event);
    });

    databaseRef.onChildAdded.listen((event) {
      _handleDatabaseEvent(event);
    });

    _isInitialized = true;
  }

  void _handleDatabaseEvent(DatabaseEvent event) {
    // Extract data from the event
    final data = event.snapshot.value;
    String notificationTitle = 'Database Updated';
    String notificationMessage = 'There\'s new content in your app!';

    // If data is a Map, you can extract more specific information
    if (data is Map) {
      // Example: If your database record has a 'status' field
      final status = data['status'];
      final shipmentId = data['shipmentId'] ?? event.snapshot.key;

      if (status != null) {
        notificationTitle = 'Shipment Status Updated';
        notificationMessage = 'Shipment $shipmentId is now $status';
      }
    }
  }
}

// App class with Provider setup
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: MaterialApp(
        title: 'D.F.R Transit Tracking',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const HomePage(),
      ),
    );
  }
}

// Data Provider for state management
class DataProvider with ChangeNotifier {
  // Your data provider implementation
  List<NotificationItem> _notifications = [];

  List<NotificationItem> get notifications => _notifications;

  void addNotification(NotificationItem notification) {
    _notifications.add(notification);
    notifyListeners();
  }

  void clearNotifications() {
    _notifications = [];
    notifyListeners();
  }
}

// Notification item model class
class NotificationItem {
  final String? title;
  final String? body;
  final Map<String, dynamic>? additionalData;
  final DateTime timestamp;

  NotificationItem({
    this.title,
    this.body,
    this.additionalData,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory NotificationItem.fromOSNotification(OSNotification notification) {
    DateTime? timestamp;
    try {
      if (notification.rawPayload?['created_at'] != null) {
        timestamp = DateTime.fromMillisecondsSinceEpoch(
            (notification.rawPayload!['created_at'] as int) * 1000);
      }
    } catch (e) {
      print('Error parsing notification timestamp: $e');
    }

    return NotificationItem(
      title: notification.title,
      body: notification.body,
      additionalData: notification.additionalData,
      timestamp: timestamp,
    );
  }
}

// Home Page implementation
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    // Setup OneSignal notification handlers
    _setupNotificationHandlers();
  }

  void _setupNotificationHandlers() {
    // Handle foreground notifications
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // Prevent the notification from displaying automatically
      event.preventDefault();

      // Manually add to our provider
      final notification =
          NotificationItem.fromOSNotification(event.notification);
      Provider.of<DataProvider>(context, listen: false)
          .addNotification(notification);

      // Optionally display the notification using OneSignal
      event.notification.display();
    });

    // Handle notification clicks
    OneSignal.Notifications.addClickListener((event) {
      print("Notification clicked: ${event.notification.title}");
      // You could navigate to a specific page based on the notification data
      if (event.notification.additionalData?['shipmentId'] != null) {
        final shipmentId = event.notification.additionalData!['shipmentId'];
        // Navigate to search screen with the shipment ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SearchScreen(initialSearch: shipmentId as String),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF93C5FD),
              Color(0xFF10B981),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/your_app_logo.png',
                      width: 300,
                      height: 300,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.local_shipping,
                            size: 80, color: Color(0xFF10B981));
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                )),
                child: FadeTransition(
                  opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
                    ),
                  ),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Text(
                      'D.F.R TRANSIT\nTRACKING',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        height: 1.1,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black.withOpacity(0.3),
                            offset: const Offset(3.0, 3.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    _buildAnimatedButton(
                      'Track Shipment',
                      Icons.search_outlined,
                      const SearchScreen(),
                      const Color(0xFF3B82F6),
                      0.5,
                    ),
                    const SizedBox(height: 20),
                    _buildAnimatedButton(
                      'Shipment History',
                      Icons.history,
                      const ShipmentHistoryPage(),
                      const Color(0xFF10B981),
                      0.6,
                    ),
                    const SizedBox(height: 20),
                    _buildAnimatedButton(
                      'Notifications',
                      Icons.notifications_outlined,
                      const NotificationsPage(),
                      Colors.orange,
                      0.7,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton(
    String text,
    IconData icon,
    Widget page,
    Color color,
    double delayFactor,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(delayFactor, 1.0, curve: Curves.easeOut),
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(delayFactor, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: _buildGlassButton(context,
            text: text, icon: icon, page: page, color: color),
      ),
    );
  }

  Widget _buildGlassButton(
    BuildContext context, {
    required String text,
    required IconData icon,
    required Widget page,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 5,
            sigmaY: 5,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        page,
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      var begin = const Offset(1.0, 0.0);
                      var end = Offset.zero;
                      var curve = Curves.easeInOutQuart;
                      var tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: color.withOpacity(0.8),
                minimumSize: const Size(double.infinity, 65),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 28, color: Colors.white),
                  const SizedBox(width: 15),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Placeholder for Shipment History Page
class ShipmentHistoryPage extends StatelessWidget {
  const ShipmentHistoryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Shipment History',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text("Shipment History"),
      ),
    );
  }
}

// Fixed NotificationsPage that properly manages the notifications
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<NotificationItem> _localNotifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      // First, get any notifications from the provider
      final providerNotifications =
          Provider.of<DataProvider>(context, listen: false).notifications;

      // Add them to local notifications
      setState(() {
        _localNotifications.clear();
        _localNotifications.addAll(providerNotifications);
      });

      // Try to get recent notifications from OneSignal
      final pushSubscription = OneSignal.User.pushSubscription;
      if (pushSubscription.optedIn == true) {
        // We can't directly get past notifications from OneSignal in this way,
        // so we'll rely on what we've captured in the app

        // Setup for future notifications
        OneSignal.Notifications.addForegroundWillDisplayListener((event) {
          final notification =
              NotificationItem.fromOSNotification(event.notification);
          setState(() => _localNotifications.add(notification));
        });
      }
    } catch (e) {
      print("Error loading notifications: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: _loadNotifications)
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _localNotifications.isEmpty
              ? _buildEmptyNotifications()
              : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyNotifications() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text('No Notifications',
              style: TextStyle(fontSize: 24, color: Colors.grey[800])),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text('You don\'t have any notifications yet',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    // Sort notifications by timestamp, most recent first
    final sortedNotifications = List<NotificationItem>.from(_localNotifications)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sortedNotifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationCard(sortedNotifications[index]);
      },
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final data = notification.additionalData;
    final shipmentId = data?['shipmentId'];
    final shipmentStatus = data?['status'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (shipmentId != null) {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SearchScreen(initialSearch: shipmentId as String)));
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildStatusIcon(shipmentStatus as String?),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.title ?? 'Notification',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(_formatDate(notification.timestamp),
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
                if (notification.body != null) ...[
                  const SizedBox(height: 12),
                  Text(notification.body!,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                ],
                if (shipmentId != null) ...[
                  const SizedBox(height: 12),
                  _buildShipmentId(shipmentId as String),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String? status) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: _getNotificationColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(_getNotificationIcon(status),
          color: _getNotificationColor(status)),
    );
  }

  Widget _buildShipmentId(String shipmentId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('Shipment ID: $shipmentId',
          style: TextStyle(
              color: Colors.blue.shade800, fontWeight: FontWeight.w500)),
    );
  }

  Color _getNotificationColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'in transit':
      case 'on the way':
        return Colors.orange;
      case 'pending':
        return Colors.yellow.shade800;
      default:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
        return Icons.check_circle;
      case 'in transit':
      case 'on the way':
        return Icons.local_shipping;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.notifications;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today, ${_formatTime(date)}';
    } else if (dateToCheck == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, ${_formatTime(date)}';
    }
    return '${date.day}/${date.month}/${date.year}, ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// Placeholder for SearchScreen
class SearchScreen extends StatelessWidget {
  final String? initialSearch;

  const SearchScreen({Key? key, this.initialSearch}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is just a placeholder since you mentioned you already have this page
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Shipment'),
        elevation: 0,
      ),
      body: Center(
        child: Text(initialSearch != null
            ? 'Searching for: $initialSearch'
            : 'Search Screen'),
      ),
    );
  }
}
