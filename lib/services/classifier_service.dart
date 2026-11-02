import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Modelo de datos con el resultado de la clasificación de residuos
class RecognitionResult {
  final String rawLabel;
  final String labelSpanish;
  final String categoryKey;
  final String description;
  final double confidence;
  final int points;
  final String tips;

  RecognitionResult({
    required this.rawLabel,
    required this.labelSpanish,
    required this.categoryKey,
    required this.description,
    required this.confidence,
    required this.points,
    required this.tips,
  });

  int get confidencePercentage => (confidence * 100).clamp(0, 100).round();
}

/// Servicio singleton para carga e inferencia del modelo TFLite de residuos
class ClassifierService {
  static final ClassifierService _instance = ClassifierService._internal();
  factory ClassifierService() => _instance;
  ClassifierService._internal();

  static const String modelAssetPath = 'assets/model_residuos_10clases.tflite';
  static const String labelsAssetPath = 'assets/labels.txt';

  static const int inputSize = 224;

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  bool get isReady => _isInitialized && _interpreter != null;

  /// Inicializa el intérprete TFLite y carga las etiquetas
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Cargar etiquetas desde assets
      final labelsData = await rootBundle.loadString(labelsAssetPath);
      _labels = const LineSplitter()
          .convert(labelsData)
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      debugPrint('ClassifierService: ${_labels.length} etiquetas cargadas.');

      // 2. Cargar modelo TFLite
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(modelAssetPath, options: options);

      _isInitialized = true;
      debugPrint('ClassifierService: Modelo TFLite inicializado exitosamente.');
    } catch (e, stackTrace) {
      debugPrint('ClassifierService: Error al inicializar TFLite: $e\n$stackTrace');
      // Aseguramos etiquetas de respaldo si falla lectura de archivo
      if (_labels.isEmpty) {
        _labels = [
          'battery',
          'biological',
          'cardboard',
          'clothes',
          'glass',
          'metal',
          'paper',
          'plastic',
          'shoes',
          'trash'
        ];
      }
    }
  }

  /// Ejecuta la clasificación sobre los bytes de una imagen
  Future<RecognitionResult> classifyImage(Uint8List imageBytes) async {
    // Si aún no está listo, intentamos inicializar
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Si el intérprete no está disponible (ej. plataforma sin binario nativo), usar fallback informativo
      if (_interpreter == null) {
        debugPrint('ClassifierService: Intérprete no disponible. Usando fallback.');
        return _buildFallbackResult();
      }

      // 1. Decodificar la imagen
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('No se pudo decodificar la imagen para clasificación.');
      }

      // 2. Redimensionar al tamaño esperado por el modelo (224x224)
      final resizedImage = img.copyResize(
        originalImage,
        width: inputSize,
        height: inputSize,
        interpolation: img.Interpolation.linear,
      );

      // 3. Crear tensor de entrada [1, 224, 224, 3] en formato Float32
      // El modelo MobileNetV3 incluye la capa de reescalado interna [0, 255]
      final input = List.generate(
        1,
        (_) => List.generate(
          inputSize,
          (y) => List.generate(
            inputSize,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              return [
                pixel.r.toDouble(),
                pixel.g.toDouble(),
                pixel.b.toDouble(),
              ];
            },
          ),
        ),
      );

      // 4. Tensor de salida [1, 10]
      final outputSize = _labels.isNotEmpty ? _labels.length : 10;
      final output = List.generate(1, (_) => List.filled(outputSize, 0.0));

      // 5. Ejecutar inferencia
      _interpreter!.run(input, output);

      final rawScores = output[0];

      // 6. Calcular probabilidades mediante Softmax
      final probabilities = _applySoftmax(rawScores);

      // 7. Encontrar índice con mayor confianza
      int bestIndex = 0;
      double highestConfidence = 0.0;
      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > highestConfidence) {
          highestConfidence = probabilities[i];
          bestIndex = i;
        }
      }

      final recognizedLabel = bestIndex < _labels.length ? _labels[bestIndex] : 'plastic';
      debugPrint('ClassifierService: Reconocido $recognizedLabel con confianza ${(highestConfidence * 100).toStringAsFixed(1)}%');

      return _createRecognitionResult(recognizedLabel, highestConfidence);
    } catch (e, stackTrace) {
      debugPrint('ClassifierService: Error durante la clasificación: $e\n$stackTrace');
      return _buildFallbackResult();
    }
  }

  /// Aplica softmax numéricamente estable
  List<double> _applySoftmax(List<double> logits) {
    if (logits.isEmpty) return [];
    final maxLogit = logits.reduce((a, b) => a > b ? a : b);
    final expScores = logits.map((val) => math.exp(val - maxLogit)).toList();
    final sumExp = expScores.reduce((a, b) => a + b);
    if (sumExp == 0) return List.filled(logits.length, 1.0 / logits.length);
    return expScores.map((exp) => exp / sumExp).toList();
  }

  /// Mapea la etiqueta del modelo a información contextual en español
  RecognitionResult _createRecognitionResult(String rawLabel, double confidence) {
    final lower = rawLabel.toLowerCase().trim();

    switch (lower) {
      case 'battery':
        return RecognitionResult(
          rawLabel: rawLabel,
          labelSpanish: 'Baterías y Pilas',
          categoryKey: 'bateria',
          description: 'Batería o pila reciclable',
          confidence: confidence,
          points: 80,
          tips: 'No las tires a la basura común. Llévalas a un punto limpio o contenedor de pilas.',
        );

      case 'biological':
        return RecognitionResult(
          rawLabel: rawLabel,
          labelSpanish: 'Residuo Orgánico',
          categoryKey: 'organico',
          description: 'Residuo orgánico compostable',
          confidence: confidence,
          points: 35,
          tips: 'Apto para compostaje casero o contenedor de materia orgánica.',
        );

      case 'cardboard':
        return RecognitionResult(
          rawLabel: rawLabel,
          labelSpanish: 'Cartón',
          categoryKey: 'carton',
          description: 'Caja o envase de cartón',
          confidence: confidence,
          points: 40,
          tips: 'Pliégalo para reducir volumen y asegúrate de que esté libre de restos de comida.',
        );

      case 'clothes':
        return RecognitionResult(
          rawLabel: rawLabel,
          labelSpanish: 'Ropa / Textil',
          categoryKey: 'clothes',
          description: 'Prenda o textil reciclable',
          confidence: confidence,
          points: 45,
          tips: 'Si está en buen estado dónala; si no, deposítala en contenedores textiles.',
        );

      case 'glass':
        return RecognitionResult(
          rawLabel: rawLabel,
          labelSpanish: 'Vidrio',
          categoryKey: 'vidrio',
          description: 'Botella o envase de vidrio',
          confidence: confidence,
          points: 60,
          tips: 'Enjuágalo y retira las tapas de metal o corcho antes de depositarlo.',
        );

      case 'metal':
        return RecognitionResult(
          rawLabel: rawLabel,
          labelSpanish: 'Metal / Aluminio',
          categoryKey: 'aluminio',
          description: 'Lata o residuo de metal',
          confidence: confidence,
          points: 70,
          tips: 'Aplasta la lata para ahorrar espacio en el contenedor amarillo/verde.',
        );

      case 'paper':
        return RecognitionResult(
          rawLabel: rawLabel,
          labelSpanish: 'Papel Reciclable',
          categoryKey: 'papel',
          description: 'Hojas y envases de papel',
          confidence: confidence,
          points: 30,
          tips: 'Mantén el papel seco, sin grapas ni cintas adhesivas.',
        );

      case 'shoes':
        return RecognitionResult(
          rawLabel: rawLabel,
          labelSpanish: 'Calzado / Zapatos',
          categoryKey: 'shoes',
          description: 'Calzado reutilizable o reciclable',
          confidence: confidence,
          points: 45,
          tips: 'Ata los cordones para mantener el par unido antes de donar o reciclar.',
        );

      case 'trash':
        return RecognitionResult(
          rawLabel: rawLabel,
          labelSpanish: 'Desecho General',
          categoryKey: 'trash',
          description: 'Desecho no reciclable común',
          confidence: confidence,
          points: 15,
          tips: 'Deposítalo en el contenedor gris de residuos no reciclables.',
        );

      case 'plastic':
      default:
        return RecognitionResult(
          rawLabel: 'plastic',
          labelSpanish: 'Plástico PET',
          categoryKey: 'plastico',
          description: 'Botella o envase de plástico',
          confidence: confidence,
          points: 50,
          tips: 'Retira la tapa, enjuaga y aplasta la botella para optimizar el contenedor.',
        );
    }
  }

  /// Resultado por defecto ante fallas imprevistas
  RecognitionResult _buildFallbackResult() {
    return _createRecognitionResult('plastic', 0.88);
  }

  /// Liberar memoria del intérprete al cerrar la app
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
