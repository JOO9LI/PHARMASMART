import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'resultat.dart';
import 'dart:async';
import 'login.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final ImagePicker picker = ImagePicker();
  String machineMessage = "";
  bool isAvailable = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    fetchMachineStatus();
    Timer.periodic(const Duration(seconds: 5), (_) => fetchMachineStatus());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  } // Vérifie régulièrement l'état de la machine pour mettre à jour l'interface en temps réel

  Future<void> fetchMachineStatus() async {
    try {
      final response = await http.get(
        Uri.parse("https://api.pharmasmart.dpdns.org/api/machine"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          machineMessage = data["msg"];
          isAvailable = data["available"];
        });
      }
    } catch (e) {
      setState(() {
        machineMessage = "Erreur de connexion à la machine";
        isAvailable = false;
      });
    }
  }

  Future<File> _fixRotation(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return imageFile;
    final fixed = img.bakeOrientation(image);
    final tempDir = await Directory.systemTemp.createTemp();
    final tempFile = File('${tempDir.path}/fixed.jpg');
    await tempFile.writeAsBytes(img.encodeJpg(fixed, quality: 90));
    return tempFile;
  } // Corrige l'orientation de l'image capturée pour éviter les problèmes d'affichage

  Future<File?> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recadrer l\'image',
          toolbarColor: const Color(0xFF0891B2),
          toolbarWidgetColor: const Color(0xFFFFFFFF),
          lockAspectRatio: false,
          initAspectRatio: CropAspectRatioPreset.original,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
          ],
        ),
        IOSUiSettings(title: 'Recadrer l\'image', minimumAspectRatio: 1.0),
      ],
    );
    if (croppedFile == null) return null;
    return File(croppedFile.path);
  } // Permet à l'utilisateur de recadrer l'image avant de l'envoyer au backend pour une meilleure précision de l'analyse

  Future<void> scanImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image == null) return;

    final fixed = await _fixRotation(File(image.path));
    final cropped = await _cropImage(fixed);
    if (cropped == null) return;

    await sendImageToBackend(cropped);
  } // Gère le processus de capture, de correction d'orientation, de recadrage et d'envoi de l'image au backend pour analyse

  Future<void> sendImageToBackend(File imageFile) async {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Empêche la fermeture du dialogue pendant le traitement
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF0891B2)),
              SizedBox(height: 16),
              Text(
                "Analyse en cours...",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api.pharmasmart.dpdns.org/api/traitement"),
      );
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
      var response = await request.send();

      if (!mounted) return;
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonData = jsonDecode(responseData);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ResultPage(result: List<Map<String, dynamic>>.from(jsonData)),
          ),
        );
      } else {
        print("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      print("Erreur connexion: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pharmasmart',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                child: const Icon(Icons.logout_rounded, size: 18),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const Login()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                const Text(
                  'Bienvenue sur Pharmasmart',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Scanner votre ordonnance en un instant!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                  ),
                ),

                const SizedBox(height: 40),

                GestureDetector(
                  onTap: isAvailable
                      ? scanImage
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 10),
                                  Text("Machine occupée..."),
                                ],
                              ),
                              backgroundColor: const Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 36,
                      horizontal: 24,
                    ),
                    foregroundDecoration: !isAvailable
                        ? BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(20),
                          )
                        : null,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isAvailable
                            ? [const Color(0xFF0891B2), const Color(0xFF0E7490)]
                            : [Colors.grey.shade500, Colors.grey.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isAvailable
                              ? const Color(0xFF0891B2).withOpacity(0.35)
                              : Colors.black26,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAvailable
                                ? Icons.document_scanner_rounded
                                : Icons.lock_clock_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          isAvailable
                              ? 'Scanner une ordonnance'
                              : 'Machine en cours de traitement',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 6),

                        Text(
                          isAvailable
                              ? 'Appuyez pour ouvrir la caméra'
                              : 'Veuillez attendre la fin du processus',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.75),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAvailable
                                    ? Icons.camera_alt_rounded
                                    : Icons.hourglass_top_rounded,
                                color: const Color(0xFF0891B2),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isAvailable
                                    ? 'Ouvrir la caméra'
                                    : 'Machine occupée',
                                style: const TextStyle(
                                  color: Color(0xFF0891B2),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'État de la machine',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAvailable
                          ? const Color(0xFF10B981).withOpacity(0.4)
                          : const Color(0xFFEF4444).withOpacity(0.4),
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? const Color(0xFF10B981).withOpacity(0.1)
                              : const Color(0xFFEF4444).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAvailable
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: isAvailable
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAvailable
                                  ? 'Machine disponible'
                                  : 'Machine indisponible',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isAvailable
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                            if (machineMessage.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                machineMessage,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isAvailable
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
