import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/voucher.dart';

class AdminVouchersPage extends StatelessWidget {
  const AdminVouchersPage({super.key});

  void _addVoucherDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final percentCtrl = TextEditingController();
    final capCtrl = TextEditingController();
    final costCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create Voucher"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Voucher Name (e.g. 50% OFF)")),
              TextField(controller: percentCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Discount Decimal (e.g. 0.50)")),
              TextField(controller: capCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Max Discount Cap ₱ (e.g. 500)")),
              TextField(controller: costCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Cost in Points (e.g. 100)")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('Vouchers').add(VoucherModel(
                name: nameCtrl.text,
                discountPercent: double.parse(percentCtrl.text),
                maxCap: double.parse(capCtrl.text),
                costInPoints: int.parse(costCtrl.text),
              ).toMap());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF002244)),
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('Vouchers').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No vouchers created."));

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var v = VoucherModel.fromMap(docs[index].data(), docs[index].id);
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.local_activity, color: Color(0xFFB8860B)),
                  title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Costs: ${v.costInPoints} Points • Cap: ₱${v.maxCap}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => FirebaseFirestore.instance.collection('Vouchers').doc(v.id).delete(),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addVoucherDialog(context),
        backgroundColor: const Color(0xFFB8860B),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Voucher", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}