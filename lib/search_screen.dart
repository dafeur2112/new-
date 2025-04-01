import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SearchScreen extends StatefulWidget {
  final String? initialSearch;

  const SearchScreen({Key? key, this.initialSearch}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final DatabaseReference databaseReference = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://transit-data-7adc4-default-rtdb.europe-west1.firebasedatabase.app/',
  ).ref().child('users');

  final TextEditingController _searchController = TextEditingController();
  List<Map<dynamic, dynamic>> searchResults = [];
  String statusMessage = '';
  bool isLoading = false;
  String _shipmentStatus = '';

  void searchDatabase(String searchTerm) async {
    setState(() {
      isLoading = true;
      statusMessage = '';
      _shipmentStatus = '';
      searchResults.clear();
    });

    try {
      DatabaseEvent event = await databaseReference.once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value is Map) {
        Map<dynamic, dynamic> dataMap = snapshot.value as Map<dynamic, dynamic>;

        bool foundMatch = false;
        dataMap.forEach((key, value) {
          if (value is Map &&
              (value['RemorqueLTA'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(searchTerm.toLowerCase())) {
            searchResults.add(value);
            foundMatch = true;

            // Check shipment status
            _shipmentStatus = value['status'] ?? 'On the way to Leoni';
          }
        });

        setState(() {
          if (!foundMatch) {
            // If no match found in database
            statusMessage = 'No matching data found';
            _shipmentStatus = 'Didn\'t come yet';
          } else {
            statusMessage = '${searchResults.length} result(s) found';
          }
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        statusMessage = 'Error searching database';
        searchResults = [];
        _shipmentStatus = 'Didn\'t come yet';
        isLoading = false;
      });
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
          'Transit Tracking',
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search Remorque/LTA',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.blue),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              searchResults.clear();
                              statusMessage = '';
                              _shipmentStatus = '';
                            });
                          },
                        ),
                      ),
                      onSubmitted: searchDatabase,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => searchDatabase(_searchController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Icon(Icons.search),
                  ),
                ],
              ),
            ),
            Expanded(
              child: searchResults.isEmpty
                  ? _buildNoResultsWidget()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _shipmentStatus.contains('Didn\'t come yet')
                      ? [Colors.orange.shade200, Colors.orange.shade400]
                      : [Colors.grey.shade200, Colors.grey.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 10),
                  )
                ],
              ),
              child: Center(
                child: Icon(
                  _shipmentStatus.contains('Didn\'t come yet')
                      ? Icons.local_shipping_outlined
                      : Icons.search_off,
                  size: 100,
                  color: Colors.white,
                ),
              ),
            ).animate().scaleXY(duration: 500.ms, begin: 0.5).fadeIn(),
            const SizedBox(height: 30),
            Text(
              _shipmentStatus.contains('Didn\'t come yet')
                  ? 'Shipment Tracking'
                  : 'No Results Found',
              style: TextStyle(
                color: _shipmentStatus.contains('Didn\'t come yet')
                    ? Colors.orange.shade700
                    : Colors.grey.shade700,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ).animate().slideY(begin: 0.5, end: 0).fadeIn(duration: 500.ms),
            const SizedBox(height: 15),
            Text(
              _shipmentStatus.contains('Didn\'t come yet')
                  ? 'Shipment is currently in transit'
                  : 'Please refine your search criteria',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ).animate().slideY(begin: 0.5, end: 0).fadeIn(duration: 600.ms),
            const SizedBox(height: 20),
            if (_shipmentStatus.contains('Didn\'t come yet'))
              ElevatedButton(
                onPressed: () {
                  // Implement refresh or tracking update logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade500,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Check for Updates',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ).animate().fadeIn(duration: 700.ms).shimmer(duration: 1500.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        var result = searchResults[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(Map<dynamic, dynamic> result) {
    String status = (result['status'] ?? '').toString().toLowerCase();
    bool isDelivered = status.contains('delivered in leoni');
    bool isOnTheWay = status.contains('on the way to leoni');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDelivered
                  ? [Colors.green.shade50, Colors.green.shade100]
                  : isOnTheWay
                      ? [Colors.yellow.shade50, Colors.yellow.shade100]
                      : [Colors.orange.shade50, Colors.orange.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDelivered
                        ? Colors.green.shade100.withOpacity(0.3)
                        : isOnTheWay
                            ? Colors.yellow.shade100.withOpacity(0.3)
                            : Colors.orange.shade100.withOpacity(0.3),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            result['RemorqueLTA'] ?? 'N/A',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 22,
                              letterSpacing: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDelivered
                                ? Colors.green.shade500
                                : isOnTheWay
                                    ? Colors.yellow.shade600
                                    : Colors.orange.shade500,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            isDelivered
                                ? 'Delivered'
                                : isOnTheWay
                                    ? 'In Transit'
                                    : 'Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _buildDetailRow('Date', result['date'] ?? 'N/A'),
                    _buildDetailRow('Operation', result['operation'] ?? 'N/A'),
                    _buildDetailRow('Transport', result['transport'] ?? 'N/A'),
                    _buildDetailRow(
                        'Packages', result['number of packages'] ?? 'N/A'),
                    _buildDetailRow('Status', result['status'] ?? 'N/A'),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isDelivered
                                  ? Icons.check_circle
                                  : isOnTheWay
                                      ? Icons.local_shipping
                                      : Icons.pending,
                              color: isDelivered
                                  ? Colors.green
                                  : isOnTheWay
                                      ? Colors.yellow.shade700
                                      : Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isDelivered
                                  ? 'Delivered to Leoni'
                                  : isOnTheWay
                                      ? 'On the way to Leoni'
                                      : 'Awaiting Shipment',
                              style: TextStyle(
                                color: isDelivered
                                    ? Colors.green.shade700
                                    : isOnTheWay
                                        ? Colors.yellow.shade800
                                        : Colors.orange.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2,
                                  size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Packages: ${result['number of packages'] ?? 'N/A'}',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideX(begin: 0.1, end: 0)
        .shimmer(duration: 1500.ms);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.grey[900]),
          ),
        ],
      ),
    );
  }
}
