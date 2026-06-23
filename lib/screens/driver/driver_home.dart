import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/ride_request_model.dart';
import '../../models/driver_route_model.dart';
import '../../services/driver_service.dart';
import '../../services/ntsa_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class DriverHome extends StatefulWidget {
  final AppUser appUser;
  const DriverHome({super.key, required this.appUser});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  int _currentIndex = 0;
  final AuthService _authService = AuthService();
  final DriverService _driverService = DriverService();
  final NTSAService _ntsaService = NTSAService();

  late bool _isOnline;
  late AppUser _appUser;
  DriverRoute? _driverRoute;
  bool _routeLoading = false;

  @override
  void initState() {
    super.initState();
    _isOnline = widget.appUser.isOnline;
    _appUser = widget.appUser;
    if (_isOnline) _loadDriverRoute();
  }

  Future<void> _loadDriverRoute() async {
    setState(() => _routeLoading = true);
    try {
      final route = await _driverService.getDriverRoute(_appUser.id);
      if (mounted) setState(() => _driverRoute = route);
    } catch (_) {}
    if (mounted) setState(() => _routeLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('TaxiSha'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _isOnline ? 'ONLINE' : 'OFFLINE',
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          if (_currentIndex == 0)
            Switch(
              value: _isOnline,
              onChanged: _toggleOnline,
              activeTrackColor: Colors.green,
            ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildRideRequestsTab(theme),
          _buildHistoryTab(theme),
          _buildProfileTab(theme),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_taxi_outlined),
            selectedIcon: Icon(Icons.local_taxi),
            label: 'Rides',
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

  Future<void> _toggleOnline(bool value) async {
    if (value && _driverRoute == null && mounted) {
      final route = await _showRouteSetupDialog();
      if (route == null) return;
      await _driverService.saveDriverRoute(route);
      if (mounted) setState(() => _driverRoute = route);
    }
    setState(() => _isOnline = value);
    try {
      await _driverService.toggleOnlineStatus(_appUser.id, value);
      if (!value && mounted) setState(() => _driverRoute = null);
      if (value && mounted) _loadDriverRoute();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOnline = !value);
    }
  }

  Widget _buildRideRequestsTab(ThemeData theme) {
    if (!_isOnline) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.power_off, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('You are offline', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Go online to receive ride requests',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    if (_routeLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_driverRoute == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text('Set your route', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Choose where you\'re heading and set your bid range',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final route = await _showRouteSetupDialog();
                if (route != null) {
                  await _driverService.saveDriverRoute(route);
                  if (mounted) setState(() => _driverRoute = route);
                }
              },
              icon: const Icon(Icons.route),
              label: const Text('Set Your Route'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildRouteCard(theme),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _driverService.getAvailableRideRequests(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final allDocs = snapshot.data?.docs ?? [];
              final docs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final rejectedBy = List<String>.from(data['rejectedBy'] ?? []);
                return !rejectedBy.contains(_appUser.id);
              }).toList();
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.taxi_alert, size: 48, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text('No ride requests', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Waiting for passengers to request rides',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: docs.map((doc) {
                  final request = RideRequest.fromMap(
                    doc.id,
                    doc.data() as Map<String, dynamic>,
                  );
                  return _buildRideRequestCard(request, theme);
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRouteCard(ThemeData theme) {
    final route = _driverRoute!;
    return Card(
      margin: const EdgeInsets.all(16),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trip_origin, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(route.pickupArea,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(route.destinationArea,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bid range: Ksh ${route.minBid.toStringAsFixed(0)} - Ksh ${route.maxBid.toStringAsFixed(0)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                final updated = await _showRouteSetupDialog(route: route);
                if (updated != null) {
                  await _driverService.saveDriverRoute(updated);
                  if (mounted) setState(() => _driverRoute = updated);
                }
              },
              child: const Text('Edit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideRequestCard(RideRequest request, ThemeData theme) {
    final withinRange = _driverRoute != null &&
        request.bidAmount >= _driverRoute!.minBid &&
        request.bidAmount <= _driverRoute!.maxBid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(Icons.person, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request.passengerName,
                          style: theme.textTheme.titleSmall),
                      Text(
                        _formatTimeAgo(request.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: withinRange ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: withinRange ? Colors.green : Colors.orange,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'Ksh ${request.bidAmount.toStringAsFixed(0)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: withinRange ? Colors.green.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildLocationRow(Icons.trip_origin, request.pickup, theme),
            const SizedBox(height: 8),
            _buildLocationRow(Icons.location_on, request.destination, theme),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectRequest(request),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _acceptRequest(request),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String text, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _acceptRequest(RideRequest request) async {
    await _driverService.acceptRideRequest(request.id, _appUser.id);
  }

  Future<void> _rejectRequest(RideRequest request) async {
    await _driverService.rejectRideRequest(request.id, _appUser.id);
  }

  Future<DriverRoute?> _showRouteSetupDialog({DriverRoute? route}) async {
    final pickupCtrl =
        TextEditingController(text: route?.pickupArea ?? '');
    final destCtrl =
        TextEditingController(text: route?.destinationArea ?? '');
    final minBidCtrl = TextEditingController(
      text: route != null && route.minBid > 0
          ? route.minBid.toStringAsFixed(0)
          : '',
    );
    final maxBidCtrl = TextEditingController(
      text: route != null && route.maxBid > 0
          ? route.maxBid.toStringAsFixed(0)
          : '',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(route != null ? 'Edit Your Route' : 'Set Your Route'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pickupCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pickup area',
                  hintText: 'e.g. Nairobi CBD',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.trip_origin),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: destCtrl,
                decoration: const InputDecoration(
                  labelText: 'Destination area',
                  hintText: 'e.g. Westlands',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              Text('Bid Range',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minBidCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Minimum (Ksh)',
                        border: OutlineInputBorder(),
                        prefixText: 'Ksh ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxBidCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Maximum (Ksh)',
                        border: OutlineInputBorder(),
                        prefixText: 'Ksh ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final minBid = double.tryParse(minBidCtrl.text) ?? 0;
              final maxBid = double.tryParse(maxBidCtrl.text) ?? 0;
              if (pickupCtrl.text.isEmpty || destCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please fill in pickup and destination')),
                );
                return;
              }
              if (minBid <= 0 || maxBid <= 0 || maxBid < minBid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Set a valid bid range (min > 0, max >= min)')),
                );
                return;
              }
              Navigator.pop(ctx, {
                'pickupArea': pickupCtrl.text,
                'destinationArea': destCtrl.text,
                'minBid': minBid,
                'maxBid': maxBid,
              });
            },
            child: const Text('Save Route'),
          ),
        ],
      ),
    );

    if (result != null) {
      return DriverRoute(
        driverId: _appUser.id,
        driverName: _appUser.name,
        pickupArea: result['pickupArea'],
        destinationArea: result['destinationArea'],
        minBid: result['minBid'],
        maxBid: result['maxBid'],
        isActive: true,
      );
    }
    return null;
  }

  Widget _buildHistoryTab(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            'No ride history',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: SwitchListTile(
              title: Text(_isOnline ? 'Go Offline' : 'Go Online'),
              subtitle: Text(
                _isOnline
                    ? 'Receiving ride requests'
                    : 'Not receiving requests',
              ),
              value: _isOnline,
              onChanged: _toggleOnline,
              secondary: Icon(
                _isOnline ? Icons.wifi : Icons.wifi_off,
                color: _isOnline ? Colors.green : Colors.grey,
              ),
            ),
          ),
          if (_driverRoute != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.route),
                title: const Text('Current Route'),
                subtitle: Text(
                  '${_driverRoute!.pickupArea} → ${_driverRoute!.destinationArea}\n'
                  'Bid: Ksh ${_driverRoute!.minBid.toStringAsFixed(0)} - ${_driverRoute!.maxBid.toStringAsFixed(0)}',
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final updated = await _showRouteSetupDialog(route: _driverRoute);
                    if (updated != null) {
                      await _driverService.saveDriverRoute(updated);
                      if (mounted) setState(() => _driverRoute = updated);
                    }
                  },
                  child: const Text('Edit'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Vehicle Details', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Make', _appUser.vehicle.make),
                  _buildInfoRow('Model', _appUser.vehicle.model),
                  _buildInfoRow('Color', _appUser.vehicle.color),
                  _buildInfoRow('Plate Number', _appUser.vehicle.plateNumber),
                  _buildInfoRow('Year', _appUser.vehicle.year > 0
                      ? _appUser.vehicle.year.toString()
                      : '-'),
                  _buildInfoRow('Seats', _appUser.vehicle.seats.toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _showEditVehicleDialog(theme),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Vehicle Details'),
          ),
          const SizedBox(height: 24),
          Text('NTSA Verification', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildNTSACard(theme),
          const SizedBox(height: 24),
          Text('Personal Info', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Name', _appUser.name),
                  _buildInfoRow('Phone', _appUser.phone),
                  _buildInfoRow('Email', _appUser.email),
                  _buildInfoRow('Rating', _appUser.ratingAvg.toStringAsFixed(1)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () async {
                await _authService.signOut();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Sign out'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  Widget _buildNTSACard(ThemeData theme) {
    final ntsa = _appUser.ntsa;
    final statusColor = ntsa.verificationStatus == 'verified'
        ? Colors.green
        : ntsa.verificationStatus == 'rejected'
            ? Colors.red
            : Colors.orange;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ntsa.verificationStatus.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _showNTSADetailsDialog(theme),
                  icon: const Icon(Icons.details, size: 18),
                  label: const Text('Details'),
                ),
              ],
            ),
            const Divider(),
            _buildNTSAItem(
                'Driving License', ntsa.licenseVerified, Icons.badge),
            _buildNTSAItem(
                'Vehicle Registration', ntsa.vehicleRegVerified, Icons.directions_car),
            _buildNTSAItem('PSV Badge', ntsa.psvBadgeVerified, Icons.verified),
            _buildNTSAItem('Insurance', ntsa.insuranceVerified, Icons.shield),
          ],
        ),
      ),
    );
  }

  Widget _buildNTSAItem(String label, bool verified, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: verified ? Colors.green : Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Icon(
            verified ? Icons.check_circle : Icons.pending,
            color: verified ? Colors.green : Colors.orange,
            size: 20,
          ),
        ],
      ),
    );
  }

  Future<void> _showEditVehicleDialog(ThemeData theme) async {
    final makeCtrl =
        TextEditingController(text: _appUser.vehicle.make);
    final modelCtrl =
        TextEditingController(text: _appUser.vehicle.model);
    final colorCtrl =
        TextEditingController(text: _appUser.vehicle.color);
    final plateCtrl =
        TextEditingController(text: _appUser.vehicle.plateNumber);
    final yearCtrl = TextEditingController(
      text: _appUser.vehicle.year > 0
          ? _appUser.vehicle.year.toString()
          : '',
    );
    final seatsCtrl = TextEditingController(
      text: _appUser.vehicle.seats.toString(),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Vehicle Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: makeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Make', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: modelCtrl,
                decoration: const InputDecoration(
                    labelText: 'Model', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(
                    labelText: 'Color', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: plateCtrl,
                decoration: const InputDecoration(
                    labelText: 'Plate Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: yearCtrl,
                decoration: const InputDecoration(
                    labelText: 'Year', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: seatsCtrl,
                decoration: const InputDecoration(
                    labelText: 'Seats', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, {
              'make': makeCtrl.text,
              'model': modelCtrl.text,
              'color': colorCtrl.text,
              'plateNumber': plateCtrl.text,
              'year': int.tryParse(yearCtrl.text) ?? 0,
              'seats': int.tryParse(seatsCtrl.text) ?? 4,
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final vehicle = VehicleInfo(
        make: result['make'],
        model: result['model'],
        color: result['color'],
        plateNumber: result['plateNumber'],
        year: result['year'],
        seats: result['seats'],
      );
      await _driverService.updateVehicleInfo(_appUser.id, vehicle);
      setState(() {
        _appUser = AppUser(
          id: _appUser.id,
          name: _appUser.name,
          phone: _appUser.phone,
          email: _appUser.email,
          role: _appUser.role,
          verificationStatus: _appUser.verificationStatus,
          ratingAvg: _appUser.ratingAvg,
          ratingCount: _appUser.ratingCount,
          isOnline: _isOnline,
          vehicle: vehicle,
          ntsa: _appUser.ntsa,
        );
      });
    }
  }

  Future<void> _showNTSADetailsDialog(ThemeData theme) async {
    final ntsa = _appUser.ntsa;
    final licenseCtrl =
        TextEditingController(text: ntsa.licenseNumber);
    final vehicleRegCtrl =
        TextEditingController(text: ntsa.vehicleRegNumber);
    final psvCtrl =
        TextEditingController(text: ntsa.psvBadgeNumber);
    final insuranceCtrl =
        TextEditingController(text: ntsa.insuranceUrl);

    final isVerified = ntsa.verificationStatus == 'verified';

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('NTSA Documents'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildNTSAField(
                label: 'Driving License',
                hint: 'e.g. ABC-1234-XYZ',
                controller: licenseCtrl,
                verified: ntsa.licenseVerified,
                onVerify: () async {
                  if (!mounted) return;
                  final result =
                      await _ntsaService.verifyDriversLicense(licenseCtrl.text);
                  if (!mounted) return;
                  if (result['verified'] == true) {
                    setState(() {
                      _appUser = AppUser(
                        id: _appUser.id,
                        name: _appUser.name,
                        phone: _appUser.phone,
                        email: _appUser.email,
                        role: _appUser.role,
                        verificationStatus: _appUser.verificationStatus,
                        ratingAvg: _appUser.ratingAvg,
                        ratingCount: _appUser.ratingCount,
                        isOnline: _isOnline,
                        vehicle: _appUser.vehicle,
                        ntsa: NTSAInfo(
                          licenseNumber: licenseCtrl.text,
                          licenseVerified: true,
                          vehicleRegNumber: _appUser.ntsa.vehicleRegNumber,
                          vehicleRegVerified: _appUser.ntsa.vehicleRegVerified,
                          psvBadgeNumber: _appUser.ntsa.psvBadgeNumber,
                          psvBadgeVerified: _appUser.ntsa.psvBadgeVerified,
                          insuranceUrl: _appUser.ntsa.insuranceUrl,
                          insuranceVerified: _appUser.ntsa.insuranceVerified,
                          verificationStatus: _appUser.ntsa.verificationStatus,
                        ),
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'])),
                    );
                    await _driverService.updateNTSAField(
                        _appUser.id, 'licenseNumber', licenseCtrl.text);
                    await _driverService.updateNTSAField(
                        _appUser.id, 'licenseVerified', true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'])),
                    );
                  }
                },
                theme: theme,
              ),
              const SizedBox(height: 16),
              _buildNTSAField(
                label: 'Vehicle Registration',
                hint: 'e.g. KCA 123T',
                controller: vehicleRegCtrl,
                verified: ntsa.vehicleRegVerified,
                onVerify: () async {
                  if (!mounted) return;
                  final result = await _ntsaService
                      .verifyVehicleRegistration(vehicleRegCtrl.text);
                  if (!mounted) return;
                  if (result['verified'] == true) {
                    setState(() {
                      _appUser = AppUser(
                        id: _appUser.id,
                        name: _appUser.name,
                        phone: _appUser.phone,
                        email: _appUser.email,
                        role: _appUser.role,
                        verificationStatus: _appUser.verificationStatus,
                        ratingAvg: _appUser.ratingAvg,
                        ratingCount: _appUser.ratingCount,
                        isOnline: _isOnline,
                        vehicle: _appUser.vehicle,
                        ntsa: NTSAInfo(
                          licenseNumber: _appUser.ntsa.licenseNumber,
                          licenseVerified: _appUser.ntsa.licenseVerified,
                          vehicleRegNumber: vehicleRegCtrl.text,
                          vehicleRegVerified: true,
                          psvBadgeNumber: _appUser.ntsa.psvBadgeNumber,
                          psvBadgeVerified: _appUser.ntsa.psvBadgeVerified,
                          insuranceUrl: _appUser.ntsa.insuranceUrl,
                          insuranceVerified: _appUser.ntsa.insuranceVerified,
                          verificationStatus:
                              _appUser.ntsa.verificationStatus,
                        ),
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'])),
                    );
                    await _driverService.updateNTSAField(
                        _appUser.id, 'vehicleRegNumber', vehicleRegCtrl.text);
                    await _driverService.updateNTSAField(
                        _appUser.id, 'vehicleRegVerified', true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'])),
                    );
                  }
                },
                theme: theme,
              ),
              const SizedBox(height: 16),
              _buildNTSAField(
                label: 'PSV Badge',
                hint: 'PSV badge number',
                controller: psvCtrl,
                verified: ntsa.psvBadgeVerified,
                onVerify: () async {
                  if (!mounted) return;
                  final result =
                      await _ntsaService.verifyPSVBadge(psvCtrl.text);
                  if (!mounted) return;
                  if (result['verified'] == true) {
                    setState(() {
                      _appUser = AppUser(
                        id: _appUser.id,
                        name: _appUser.name,
                        phone: _appUser.phone,
                        email: _appUser.email,
                        role: _appUser.role,
                        verificationStatus: _appUser.verificationStatus,
                        ratingAvg: _appUser.ratingAvg,
                        ratingCount: _appUser.ratingCount,
                        isOnline: _isOnline,
                        vehicle: _appUser.vehicle,
                        ntsa: NTSAInfo(
                          licenseNumber: _appUser.ntsa.licenseNumber,
                          licenseVerified: _appUser.ntsa.licenseVerified,
                          vehicleRegNumber: _appUser.ntsa.vehicleRegNumber,
                          vehicleRegVerified:
                              _appUser.ntsa.vehicleRegVerified,
                          psvBadgeNumber: psvCtrl.text,
                          psvBadgeVerified: true,
                          insuranceUrl: _appUser.ntsa.insuranceUrl,
                          insuranceVerified: _appUser.ntsa.insuranceVerified,
                          verificationStatus:
                              _appUser.ntsa.verificationStatus,
                        ),
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'])),
                    );
                    await _driverService.updateNTSAField(
                        _appUser.id, 'psvBadgeNumber', psvCtrl.text);
                    await _driverService.updateNTSAField(
                        _appUser.id, 'psvBadgeVerified', true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'])),
                    );
                  }
                },
                theme: theme,
              ),
              const SizedBox(height: 16),
              _buildNTSAField(
                label: 'Insurance Policy',
                hint: 'Policy number',
                controller: insuranceCtrl,
                verified: ntsa.insuranceVerified,
                onVerify: () async {
                  if (!mounted) return;
                  final result =
                      await _ntsaService.verifyInsurance(insuranceCtrl.text);
                  if (!mounted) return;
                  if (result['verified'] == true) {
                    setState(() {
                      _appUser = AppUser(
                        id: _appUser.id,
                        name: _appUser.name,
                        phone: _appUser.phone,
                        email: _appUser.email,
                        role: _appUser.role,
                        verificationStatus: _appUser.verificationStatus,
                        ratingAvg: _appUser.ratingAvg,
                        ratingCount: _appUser.ratingCount,
                        isOnline: _isOnline,
                        vehicle: _appUser.vehicle,
                        ntsa: NTSAInfo(
                          licenseNumber: _appUser.ntsa.licenseNumber,
                          licenseVerified: _appUser.ntsa.licenseVerified,
                          vehicleRegNumber: _appUser.ntsa.vehicleRegNumber,
                          vehicleRegVerified:
                              _appUser.ntsa.vehicleRegVerified,
                          psvBadgeNumber: _appUser.ntsa.psvBadgeNumber,
                          psvBadgeVerified: _appUser.ntsa.psvBadgeVerified,
                          insuranceUrl: insuranceCtrl.text,
                          insuranceVerified: true,
                          verificationStatus:
                              _appUser.ntsa.verificationStatus,
                        ),
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'])),
                    );
                    await _driverService.updateNTSAField(
                        _appUser.id, 'insuranceUrl', insuranceCtrl.text);
                    await _driverService.updateNTSAField(
                        _appUser.id, 'insuranceVerified', true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(result['message'])),
                    );
                  }
                },
                theme: theme,
              ),
              if (isVerified)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text('All documents verified',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.green)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildNTSAField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool verified,
    required VoidCallback onVerify,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
            suffixIcon: verified
                ? const Icon(Icons.check_circle, color: Colors.green)
                : IconButton(
                    icon: const Icon(Icons.verified),
                    onPressed: controller.text.isEmpty ? null : onVerify,
                  ),
          ),
        ),
      ],
    );
  }
}
