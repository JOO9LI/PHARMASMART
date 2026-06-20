import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pharmasmart/login.dart';

class ResultPage extends StatefulWidget {
  final List<Map<String, dynamic>> result;

  const ResultPage({super.key, required this.result});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage>
    with SingleTickerProviderStateMixin {
  late List<Map<String, dynamic>> medications;
  List<dynamic> stock =
      []; //liste complète du stock de médicaments récupérée depuis l'API
  List<dynamic> filteredStock =
      []; //liste filtrée du stock en fonction de la recherche
  TextEditingController searchController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  // Récupère les données passées depuis la page précédente et initialise les animations
  @override
  void initState() {
    super.initState();
    medications = List<Map<String, dynamic>>.from(widget.result);
    fetchStock();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    searchController.dispose();
    super.dispose();
  } // Récupère le stock de médicaments depuis l'API et met à jour l'état

  Future<void> fetchStock() async {
    try {
      final response = await http.get(
        Uri.parse("https://api.pharmasmart.dpdns.org/api/medicine"),
      );
      if (response.statusCode == 200) {
        stock = jsonDecode(response.body);
        filteredStock = stock;
        setState(() {});
      }
    } catch (e) {}
  }

  void openSearch() {
    searchController.clear();
    filteredStock = List.from(stock);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 16),
                  const Text(
                    'Ajouter un médicament',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: searchController,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Rechercher un médicament...",
                      hintStyle: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF0891B2),
                        size: 20,
                      ),
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
                        borderSide: const BorderSide(
                          color: Color(0xFF0891B2),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        filteredStock = stock
                            .where(
                              (item) => item["name"].toLowerCase().contains(
                                val.toLowerCase(),
                              ), // Filtre les médicaments en fonction de la recherche
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 280,
                    child: filteredStock.isEmpty
                        ? const Center(
                            child: Text(
                              'Aucun résultat',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredStock.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (context, index) {
                              final item =
                                  filteredStock[index]; // Affiche la liste des médicaments filtrés
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF0891B2,
                                    ).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.medication_rounded,
                                    color: Color(0xFF0891B2),
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  item["name"],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: Color(0xFF0891B2),
                                  size: 20,
                                ),
                                onTap: () {
                                  setState(() {
                                    final indexExist = medications.indexWhere(
                                      (e) =>
                                          e["medicine"].toLowerCase() ==
                                          item["name"].toLowerCase(),
                                    ); // Vérifie si le médicament existe déjà dans la liste
                                    if (indexExist != -1) {
                                      medications[indexExist]["quantity"]++; // Si oui, incrémente la quantité
                                    } else {
                                      medications.add({
                                        "medicine":
                                            item["name"], // Sinon, ajoute le médicament à la liste avec une quantité de 1
                                        "quantity": 1,
                                      });
                                    }
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> validateMedication() async {
    try {
      final payload = {"medications": medications, "status": "start"};

      final espResponse = await http.post(
        Uri.parse("https://api.pharmasmart.dpdns.org/api/validate"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${AuthToken.token}",
        },
        body: jsonEncode(payload),
      );

      if (!mounted) return;

      final espData = jsonDecode(espResponse.body);

      if (espResponse.statusCode != 200 || espData["success"] != true) {
        final errorMessage =
            espData["error"] ?? espData["message"] ?? "Validation échouée";

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );

        return;
      }

      final historyPayload = medications
          .map(
            (item) => {
              "medicine": item["medicine"],
              "quantity": item["quantity"],
              "transaction": "remove",
            }, // Prépare les données à envoyer pour l'historique en fonction des médicaments validés
          )
          .toList();

      final historyResponse = await http.post(
        Uri.parse("https://api.pharmasmart.dpdns.org/api/historique"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${AuthToken.token}",
        },
        body: jsonEncode(historyPayload),
      );

      if (historyResponse.statusCode == 200 ||
          historyResponse.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Processus lancé avec succès'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
          ),
        );

        Navigator.pop(context);
      } else {
        throw Exception("Historique failed");
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Erreur lors de la validation'),
            ],
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Résultat',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0891B2),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // box info ordonnance
                Container(
                  width: double.infinity, // Prend toute la largeur disponible
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ordonnance scannée',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF065F46),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Vérifiez les informations extraites ci-dessous',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // médicaments détectés + nombre
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Médicaments détectés",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0891B2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${medications.length} item${medications.length > 1 ? 's' : ''}', // Pluriel si > 1
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0891B2),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // medicaments list
                Expanded(
                  // Prend tout l'espace restant
                  child: medications.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.medication_outlined,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Aucun médicament',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: medications.length,
                          itemBuilder: (context, index) {
                            final item = medications[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Icône
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0891B2,
                                      ).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.medication_rounded,
                                      color: Color(0xFF0891B2),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Nom
                                  Expanded(
                                    child: Text(
                                      item["medicine"],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),

                                  // Quantité
                                  Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(
                                              Icons.remove,
                                              size: 14,
                                              color: Color(0xFF64748B),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                if (item["quantity"] >
                                                    1) //empêche de descendre en dessous de 1
                                                  item["quantity"]--;
                                              });
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: Text(
                                            '${item["quantity"]}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 30,
                                          height: 30,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(
                                              Icons.add,
                                              size: 14,
                                              color: Color(0xFF0891B2),
                                            ),
                                            onPressed: () {
                                              setState(
                                                () =>
                                                    item["quantity"]++, // Incrémente la quantité
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // Supprimer
                                  GestureDetector(
                                    onTap: () => setState(
                                      () => medications.removeAt(index),
                                    ),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFEF4444,
                                        ).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 12),

                // ajouter medicament manuellement
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: openSearch,
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Color(0xFF0891B2),
                    ),
                    label: const Text(
                      'Ajouter manuellement',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0891B2),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF0891B2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // validation + annulation
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Annuler',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: medications.isEmpty
                              ? null // Désactive le bouton si aucun médicament
                              : () async {
                                  if (!mounted)
                                    return; // Vérifie que le widget est toujours monté avant de continuer
                                  await validateMedication();
                                },
                          icon: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          label: const Text(
                            'Valider',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            disabledBackgroundColor: const Color(
                              0xFFCBD5E1,
                            ), // Couleur lorsque le bouton est désactivé
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
