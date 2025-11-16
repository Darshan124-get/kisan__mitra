import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/service_provider.dart';
import '../../providers/booking_provider.dart';
import 'add_edit_service_screen.dart';

class ServiceDetailsScreen extends ConsumerWidget {
  final String serviceId;

  const ServiceDetailsScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceProvider(serviceId));
    final bookingsAsync = ref.watch(bookingNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Details'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddEditServiceScreen(serviceId: serviceId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: serviceAsync.when(
        data: (service) {
          int totalBookings = 0;
          int completedBookings = 0;
          int pendingBookings = 0;
          double totalEarnings = 0.0;

          bookingsAsync.whenData((bookings) {
            final serviceBookings = bookings.where((b) => b.serviceId == serviceId).toList();
            totalBookings = serviceBookings.length;
            completedBookings = serviceBookings
                .where((b) => b.status.toString() == 'completed')
                .length;
            pendingBookings = serviceBookings
                .where((b) => b.status.toString() == 'pending')
                .length;
            totalEarnings = serviceBookings
                .where((b) => b.status.toString() == 'completed')
                .map((b) => b.totalPrice)
                .fold(0.0, (sum, price) => sum + price);
          });

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Images
                if (service.images.isNotEmpty)
                  SizedBox(
                    height: 250,
                    child: PageView.builder(
                      itemCount: service.images.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: service.images[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 64),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Price
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              service.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '₹${service.pricePerHour}/hour',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service.serviceType.displayName,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      // Description
                      if (service.description.isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(service.description),
                        const SizedBox(height: 16),
                      ],
                      // Booking Statistics
                      const Text(
                        'Booking Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard('Total', totalBookings.toString(), Colors.blue),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard('Completed', completedBookings.toString(), Colors.green),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatCard('Pending', pendingBookings.toString(), Colors.orange),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _StatCard('Total Earnings', '₹${totalEarnings.toStringAsFixed(0)}', Colors.purple, fullWidth: true),
                      const SizedBox(height: 16),
                      // Reviews
                      const Text(
                        'Reviews & Ratings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (service.reviews.isEmpty)
                        const Text('No reviews yet')
                      else
                        ...service.reviews.map((review) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(review.farmerName?[0] ?? 'F'),
                            ),
                            title: Row(
                              children: [
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < review.rating.toInt()
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  );
                                }),
                                const SizedBox(width: 8),
                                Text(
                                  review.farmerName ?? 'Anonymous',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            subtitle: review.comment != null && review.comment!.isNotEmpty
                                ? Text(review.comment!)
                                : null,
                            trailing: Text(
                              '${review.date.day}/${review.date.month}/${review.date.year}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        )),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool fullWidth;

  const _StatCard(this.label, this.value, this.color, {this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

