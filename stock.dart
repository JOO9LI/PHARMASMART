import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Stock extends StatefulWidget {
  const Stock({super.key});

  @override
  State<Stock> createState() => _StockState();
}

class _StockState extends State<Stock> with SingleTickerProviderStateMixin {
  late Future<List<dynamic>>
  stockFuture; // Future pour stocker les données du stock et gérer le chargement
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    stockFuture = fetchStock();
    _animController = AnimationController(
      vsync: this, // Fournit un ticker pour les animations
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  } // Fonction pour récupérer les données du stock depuis l'API

  Future<List<dynamic>> fetchStock() async {
    final response = await http.get(
      Uri.parse("https://api.pharmasmart.dpdns.org/api/medicine"),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erreur de chargement");
    }
  }

  Future<void> refreshStock() async {
    setState(() {
      stockFuture = fetchStock();
    });
    await stockFuture; // Attends que le stock soit rechargé avant de terminer le rafraîchissement
  }

  void _showSnackBar(
    String message,
    Color color, {
    IconData icon = Icons.info_outline,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior
            .floating, // Affiche le SnackBar au-dessus du contenu
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> supprimer(Map med) async {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Supprimer le médicament',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Voulez-vous supprimer "${med["name"]}" du stock ?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await http.delete(
                          Uri.parse(
                            "https://api.pharmasmart.dpdns.org/api/medicine/${med["name"]}",
                          ),
                        );
                        setState(() => stockFuture = fetchStock());
                        _showSnackBar(
                          '${med["name"]} supprimé',
                          const Color(0xFFEF4444),
                          icon: Icons.delete_outline,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Supprimer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMedForm({Map? med}) {
    final isEdit = med != null;
    final name = TextEditingController(text: med?["name"] ?? '');
    final desc = TextEditingController(text: med?["description"] ?? '');
    final qty = TextEditingController(text: med?["quantity"]?.toString() ?? '');
    final minQty = TextEditingController(
      text: med?["min_quantity"]?.toString() ?? '',
    );
    final pos = TextEditingController(text: med?["position"]?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Aligne le contenu à gauche
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0891B2).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_rounded : Icons.add_rounded,
                      color: const Color(0xFF0891B2),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Modifier médicament' : 'Ajouter médicament',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _formField(
                controller: name,
                label: 'Nom',
                icon: Icons.medication_rounded,
              ),
              const SizedBox(height: 14),
              _formField(
                controller: desc,
                label: 'Description',
                icon: Icons.description_outlined,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _formField(
                      controller: qty,
                      label: 'Quantité',
                      icon: Icons.inventory_2_outlined,
                      isNumber: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _formField(
                      controller: minQty,
                      label: 'Qté minimum',
                      icon: Icons.warning_amber_rounded,
                      isNumber: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _formField(
                controller: pos,
                label: 'Position',
                icon: Icons.place_outlined,
                isNumber: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final body = jsonEncode({
                      "name": name.text,
                      "description": desc.text,
                      "quantity": int.tryParse(qty.text) ?? 0,
                      "min_quantity": int.tryParse(minQty.text) ?? 0,
                      "position": int.tryParse(pos.text) ?? 0,
                    });

                    if (isEdit) {
                      await http.put(
                        Uri.parse(
                          "https://api.pharmasmart.dpdns.org/api/medicine/${med["name"]}",
                        ),
                        headers: {"Content-Type": "application/json"},
                        body: body,
                      );
                    } else {
                      await http.post(
                        Uri.parse(
                          "https://api.pharmasmart.dpdns.org/api/medicine",
                        ),
                        headers: {"Content-Type": "application/json"},
                        body: body,
                      );
                    }

                    Navigator.pop(context);
                    setState(() => stockFuture = fetchStock());
                    _showSnackBar(
                      isEdit ? 'Médicament modifié' : 'Médicament ajouté',
                      const Color(0xFF10B981),
                      icon: Icons.check_circle_outline,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0891B2),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEdit ? 'Enregistrer' : 'Ajouter',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF0891B2), size: 18),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0891B2), width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Stock des médicaments',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0891B2),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add_rounded, size: 20),
              ),
              onPressed: () => _showMedForm(),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: FutureBuilder<List<dynamic>>(
          future: stockFuture,
          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF0891B2)),
              );
            }

            final medicines = snapshot.data ?? [];

            return RefreshIndicator(
              color: const Color(0xFF0891B2),
              onRefresh: refreshStock,
              child: () {
                // Error
                if (snapshot.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Erreur de chargement',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // Empty
                if (medicines.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 48,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Aucun médicament en stock',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // List
                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: medicines.length,
                  itemBuilder: (context, index) {
                    final med = medicines[index];
                    final int quantity = med["quantity"] ?? 0;
                    final int minQuantity = med["min_quantity"] ?? 0;
                    final bool lowStock = quantity < minQuantity;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: lowStock
                              ? const Color(0xFFEF4444).withOpacity(0.35)
                              : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: lowStock
                                        ? const Color(
                                            0xFFEF4444,
                                          ).withOpacity(0.08)
                                        : const Color(
                                            0xFF0891B2,
                                          ).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.medication_rounded,
                                    color: lowStock
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF0891B2),
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        med["name"] ?? "",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      if ((med["description"] ?? "").isNotEmpty)
                                        Text(
                                          med["description"],
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF94A3B8),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_square,
                                    color: Color(0xFF0891B2),
                                    size: 18,
                                  ),
                                  onPressed: () => _showMedForm(med: med),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 18,
                                  ),
                                  onPressed: () => supprimer(med),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _infoChip(
                                  label: 'Qté',
                                  value: '$quantity',
                                  color: lowStock
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFF10B981),
                                ),
                                const SizedBox(width: 8),
                                _infoChip(
                                  label: 'Min',
                                  value: '$minQuantity',
                                  color: const Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 8),
                                _infoChip(
                                  label: 'Pos',
                                  value: '${med["position"] ?? ""}',
                                  color: const Color(0xFF0891B2),
                                ),
                                const Spacer(),
                                if (lowStock)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEF4444,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Color(0xFFEF4444),
                                          size: 13,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Stock faible',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }(),
            );
          },
        ),
      ),
    );
  }

  Widget _infoChip({
    required String label,
    required String value,
    required Color color,
  }) // Petite étiquette d'information pour afficher la quantité, position....
  {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label : ',
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.7)),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
