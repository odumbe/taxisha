import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/passenger_service.dart';
import '../../models/ride_request_model.dart';
import '../auth/login_screen.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  int _currentIndex = 0;
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _bidController = TextEditingController();
  final _passengerService = PassengerService();
  String? _passengerName;
  String? _passengerPhone;
  String? _passengerEmail;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final appUser = await AuthService().getCurrentAppUser();
      if (appUser != null && mounted) {
        setState(() {
          _passengerName = appUser.name;
          _passengerPhone = appUser.phone;
          _passengerEmail = appUser.email;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _bidController.dispose();
    super.dispose();
  }

  Future<void> _submitRideRequest() async {
    final pickup = _pickupController.text.trim();
    final destination = _destinationController.text.trim();
    final bidText = _bidController.text.trim();

    if (pickup.isEmpty || destination.isEmpty || bidText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final bid = double.tryParse(bidText);
    if (bid == null || bid <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bid amount')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = true);
    try {
      await _passengerService.createRideRequest(
        passengerName: _passengerName ?? '',
        passengerPhone: _passengerPhone ?? '',
        pickup: pickup,
        destination: destination,
        bidAmount: bid,
      );
      _pickupController.clear();
      _destinationController.clear();
      _bidController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create ride request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    try {
      await _passengerService.cancelRideRequest(requestId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screens = [
      _buildRideTab(theme),
      _buildHistoryTab(theme),
      _buildProfileTab(theme),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('TaxiSha'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ride',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildRideTab(ThemeData theme) {
    return StreamBuilder<RideRequest?>(
      stream: _passengerService.activeRequestStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final activeRequest = snapshot.data;
        if (activeRequest != null) {
          return _buildActiveRequest(theme, activeRequest);
        }
        return _buildRequestForm(theme);
      },
    );
  }

  Widget _buildRequestForm(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.taxi_alert,
                      size: 48, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('Where are you going?',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _pickupController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.trip_origin),
                      labelText: 'Pickup location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _destinationController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.location_on),
                      labelText: 'Destination',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bidController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                      labelText: 'Your bid (KES)',
                      hintText: 'e.g. 300',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isSubmitting ? null : _submitRideRequest,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.search),
                    label: Text(
                        _isSubmitting ? 'Submitting...' : 'Find a shared ride'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Recent rides', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car_outlined,
                      size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 8),
                  Text('No rides yet',
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRequest(ThemeData theme, RideRequest request) {
    final isPending = request.status == 'pending';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    isPending ? Icons.hourglass_empty : Icons.check_circle,
                    size: 64,
                    color: isPending ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isPending ? 'Looking for a driver...' : 'Driver assigned!',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPending
                        ? 'Please wait while we find a driver for your route'
                        : 'A driver has accepted your ride request',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 32),
                  _buildDetailRow(
                      Icons.trip_origin, 'Pickup', request.pickup),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.location_on, 'Destination',
                      request.destination),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.monetization_on, 'Bid',
                      'KES ${request.bidAmount.toStringAsFixed(0)}'),
                  if (isPending) ...[
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => _cancelRequest(request.id),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel request'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500)),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w400, color: Colors.black87))),
      ],
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    return StreamBuilder<List<RideRequest>>(
      stream: _passengerService.historyStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final rides = snapshot.data ?? [];
        if (rides.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history,
                    size: 64, color: theme.colorScheme.outline),
                const SizedBox(height: 12),
                Text('No ride history',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rides.length,
          itemBuilder: (context, index) {
            final ride = rides[index];
            final isCompleted = ride.status == 'completed';
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCompleted
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.red.withValues(alpha: 0.15),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.cancel,
                    color: isCompleted ? Colors.green : Colors.red,
                  ),
                ),
                title: Text('${ride.pickup}  \u2192  ${ride.destination}'),
                subtitle: Text(
                    'KES ${ride.bidAmount.toStringAsFixed(0)}  \u2022  ${ride.status}'),
                isThreeLine: false,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 24),
          CircleAvatar(
            radius: 44,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(Icons.person,
                size: 44, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(_passengerName ?? 'Passenger',
              style: theme.textTheme.headlineSmall),
          if (_passengerEmail != null) ...[
            const SizedBox(height: 4),
            Text(_passengerEmail!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
          ],
          const SizedBox(height: 8),
          if (_passengerPhone != null)
            Text(_passengerPhone!,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () async {
                await AuthService().signOut();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Sign out'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
