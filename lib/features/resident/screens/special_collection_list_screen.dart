import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/special_collection_service.dart';
import '../../../core/utils/animations.dart';
import '../../../widgets/modern_card.dart';
import '../../../widgets/shimmer_loading.dart';
import '../../../widgets/premium_app_bar.dart';
import '../../../widgets/gradient_background.dart';
import 'special_collection_request_screen.dart';

class SpecialCollectionListScreen extends StatefulWidget {
  const SpecialCollectionListScreen({super.key});

  @override
  State<SpecialCollectionListScreen> createState() =>
      _SpecialCollectionListScreenState();
}

class _SpecialCollectionListScreenState
    extends State<SpecialCollectionListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service =
          Provider.of<SpecialCollectionService>(context, listen: false);

      await service
          .loadSpecialCollections(); // Use the resident-specific loader

      setState(() {
        _requests = service.specialCollections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load requests: $e';
        _isLoading = false;
      });

      _showSnackBar(
        'Failed to load requests. Please try again.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final specialCollectionService =
        Provider.of<SpecialCollectionService>(context);

    final requests = specialCollectionService.specialCollections;

    return Scaffold(
      appBar: PremiumAppBar(
        title: const Text('My Special Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: () => _fetchRequests(),
          ),
        ],
      ),
      body: GradientBackground(
        economyTheme: true,
        child: RefreshIndicator(
          onRefresh: () async {
            await specialCollectionService.loadSpecialCollections();
          },
          child: _isLoading
              ? ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.spacing4),
                  itemCount: 5,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTheme.spacing3),
                  itemBuilder: (context, index) =>
                      const CardSkeleton(height: 150),
                )
              : requests.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppTheme.spacing4),
                      itemCount: requests.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppTheme.spacing3),
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return AppAnimations.fadeInSlideUp(
                          duration: AppAnimations.normal,
                          offset: 20,
                          child: _buildRequestCard(context, request, index),
                        );
                      },
                    ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToRequestScreen(),
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  Widget _buildCollectionsList(
      BuildContext context, SpecialCollectionService service) {
    final collections = service.specialCollections;

    if (collections.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacing4,
        vertical: AppTheme.spacing4,
      ),
      itemCount: collections.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(
          context,
          collections[index],
          index,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.recycling,
              size: 80,
              color: AppTheme.textLight,
            ),
            const SizedBox(height: AppTheme.spacing4),
            Text(
              'No special collections yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textLight,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacing2),
            Text(
              'Request a special collection to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textLight,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    Map<String, dynamic> collection,
    int index,
  ) {
    final status =
        (collection['status']?.toString() ?? 'pending').toLowerCase();
    final wasteType = collection['wasteType'] ?? 'General Waste';
    final quantity = collection['estimatedQuantity'] ?? 'Unknown';

    final createdAt = collection['createdAt'] as DateTime?;

    return ModernCard(
      padding: const EdgeInsets.all(AppTheme.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  wasteType,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: AppTheme.spacing3),
          _buildDetailRow(
            Icons.inventory_2_outlined,
            'Quantity',
            quantity,
          ),
          if (createdAt != null) ...[
            const SizedBox(height: AppTheme.spacing2),
            _buildDetailRow(
              Icons.access_time,
              'Requested',
              _formatRelativeTime(createdAt),
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: AppTheme.spacing4),
            _buildAwaitingApprovalInfo(),
          ],
          if (status != 'completed' && status != 'cancelled') ...[
            const SizedBox(height: AppTheme.spacing3),
            _buildActionButtons(collection, status),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: highlight ? AppTheme.primaryGreen : AppTheme.textLight,
        ),
        const SizedBox(width: AppTheme.spacing2),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppTheme.textLight,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: highlight ? AppTheme.primaryGreen : AppTheme.textDark,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    if (kDebugMode) debugPrint('🔎 Mobile App Status Check: "$status"');
    Color bgColor;
    Color textColor;
    String displayText;

    switch (status) {
      case 'pending':
        bgColor = AppTheme.accentOrange.withOpacity(0.1);
        textColor = AppTheme.accentOrange;
        displayText = 'Waiting Approval';
        break;

      case 'approved':
        bgColor = AppTheme.infoBlue.withOpacity(0.1);
        textColor = AppTheme.infoBlue;
        displayText = 'Approved';
        break;

      case 'scheduled':
        bgColor = AppTheme.primaryGreen.withOpacity(0.1);
        textColor = AppTheme.primaryGreen;
        displayText = 'Scheduled';
        break;

      case 'completed':
        bgColor = AppTheme.successGreen.withOpacity(0.1);
        textColor = AppTheme.successGreen;
        displayText = 'Completed';
        break;

      case 'cancelled':
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        displayText = 'Cancelled';
        break;

      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAwaitingApprovalInfo() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing3),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentOrange.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.hourglass_top_rounded,
              size: 20, color: AppTheme.accentOrange),
          const SizedBox(width: AppTheme.spacing3),
          const Expanded(
            child: Text(
              'Your request is awaiting administrative approval. You will be notified once approved.',
              style: TextStyle(fontSize: 13, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    Map<String, dynamic> collection,
    String status,
  ) {
    return Column(
      children: [
        // approved requests no longer display any extra buttons
        // all actions are handled via cancel only
        if (status == 'pending' ||
            status == 'approved' ||
            status == 'scheduled')
          Padding(
            padding: EdgeInsets.only(
                top: (status == 'pending' || status == 'approved')
                    ? AppTheme.spacing2
                    : 0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmCancelRequest(collection),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppTheme.spacing3),
                ),
                icon: const Icon(Icons.cancel, size: 18),
                label: const Text('Cancel Request'),
              ),
            ),
          ),
      ],
    );
  }

  void _navigateToRequestScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SpecialCollectionRequestScreen(),
      ),
    ).then((value) {
      if (value == true) {
        _fetchRequests(); // Refresh list if a new request was made
      }
    });
  }

  void _confirmCancelRequest(Map<String, dynamic> collection) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Request?'),
          content: const Text(
            'Are you sure you want to cancel this special collection request? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                final service = Provider.of<SpecialCollectionService>(
                  context,
                  listen: false,
                );

                final success = await service.cancelRequest(
                  collectionId: collection['id'],
                );

                if (mounted) {
                  if (success) {
                    _showSnackBar('Request cancelled successfully');
                    _fetchRequests();
                  } else {
                    _showSnackBar('Failed to cancel request', isError: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
