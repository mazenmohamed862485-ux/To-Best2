import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/app_providers.dart';
import '../../../services/api_service.dart';

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});
  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final api = ref.read(apiServiceProvider);
    final logs = await api.getAuditLog();
    if (mounted) setState(() { _logs = logs; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final isAr = settings.language == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'سجل التعديلات' : 'Audit Log', style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w700)),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: _loading ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty ? Center(child: Text(isAr ? 'السجل فارغ' : 'Log is empty', style: const TextStyle(fontFamily: 'Cairo', color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _logs.length,
              itemBuilder: (ctx, i) {
                final log = _logs[i];
                final ts = log['ts'] as int? ?? 0;
                final dt = ts > 0 ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
                return Card(margin: const EdgeInsets.only(bottom: 6), child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.history, size: 18),
                  title: Text(log['action']?.toString() ?? '', style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text('${log['by'] ?? ""} → ${log['target'] ?? ""}', style: const TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Colors.grey)),
                  trailing: dt != null ? Text('${dt.hour}:${dt.minute.toString().padLeft(2,'0')}\n${dt.day}/${dt.month}', style: const TextStyle(fontSize: 10, fontFamily: 'Cairo', color: Colors.grey), textAlign: TextAlign.center) : null,
                ));
              }),
    );
  }
}
