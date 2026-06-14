// subscription_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_utils.dart';
import '../../../models/app_models.dart';
import '../../../providers/app_providers.dart';
import '../../../services/api_service.dart';

class SubscriptionRequestsScreen extends ConsumerStatefulWidget {
  const SubscriptionRequestsScreen({super.key});
  @override
  ConsumerState<SubscriptionRequestsScreen> createState() => _SubscriptionRequestsScreenState();
}

class _SubscriptionRequestsScreenState extends ConsumerState<SubscriptionRequestsScreen> {
  List<SubscriptionRequest> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ref.read(apiServiceProvider);
    final data = await api.getSubscriptionRequests();
    if (mounted) {
      setState(() {
        _requests = data.map((r) => SubscriptionRequest.fromJson(r)).toList();
        _loading = false;
      });
    }
  }

  Future<void> _approve(SubscriptionRequest req) async {
    final api = ref.read(apiServiceProvider);
    final endMs = DateTime.now().add(Duration(days: 30 * req.months)).millisecondsSinceEpoch;
    final ok = await api.updateSubscriptionRequest(req.id, 'approved', {
      'subscriptionStatus': 'active',
      'subscriptionType': req.planId,
      'subscriptionStart': DateTime.now().millisecondsSinceEpoch,
      'subscriptionEnd': endMs,
    });
    if (ok && mounted) {
      AppUtils.showSnack(context, 'تمت الموافقة ✓', isSuccess: true);
      await _load();
    }
  }

  Future<void> _reject(SubscriptionRequest req) async {
    final api = ref.read(apiServiceProvider);
    final ok = await api.updateSubscriptionRequest(req.id, 'rejected', {});
    if (ok && mounted) {
      AppUtils.showSnack(context, 'تم الرفض', isError: true);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'طلبات الاشتراك' : 'Subscription Requests',
            style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(child: Text(isAr ? 'لا توجد طلبات' : 'No requests', style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _requests.length,
                  itemBuilder: (ctx, i) {
                    final req = _requests[i];
                    final statusColor = req.status == 'approved' ? AppColors.ok : req.status == 'rejected' ? AppColors.error : AppColors.warn;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(req.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Cairo', fontSize: 15))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                                  child: Text(req.status, style: TextStyle(color: statusColor, fontSize: 11, fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('${isAr ? "الخطة" : "Plan"}: ${req.planId}  •  ${req.months} ${isAr ? "شهر" : "month(s)"}  •  ${req.amount} ${isAr ? "جنيه" : "EGP"}',
                                style: const TextStyle(fontFamily: 'Cairo', fontSize: 13)),
                            if (req.promoCode != null)
                              Text('${isAr ? "كود" : "Promo"}: ${req.promoCode}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12, color: Colors.grey)),
                            if (req.paymentProofUrl != null)
                              TextButton.icon(
                                icon: const Icon(Icons.image, size: 16),
                                label: Text(isAr ? 'عرض إثبات الدفع' : 'View Payment Proof', style: const TextStyle(fontFamily: 'Cairo', fontSize: 12)),
                                onPressed: () {},
                              ),
                            if (req.status == 'pending') ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _approve(req),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: Text(isAr ? 'موافقة' : 'Approve', style: const TextStyle(fontFamily: 'Cairo')),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.ok),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _reject(req),
                                      icon: const Icon(Icons.close, size: 16),
                                      label: Text(isAr ? 'رفض' : 'Reject', style: const TextStyle(fontFamily: 'Cairo')),
                                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
