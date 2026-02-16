class Medicine {
  final String id;
  final String name;
  final String genericName;
  final String manufacturer;
  final String dosage;
  final String form;
  final String? description;
  final List<String> indications;
  final List<String> contraindications;
  final List<String> sideEffects;
  final String? imageUrl;
  final double price;
  final bool requiresPrescription;
  final String? barcode;

  Medicine({
    required this.id,
    required this.name,
    required this.genericName,
    required this.manufacturer,
    required this.dosage,
    required this.form,
    this.description,
    this.indications = const [],
    this.contraindications = const [],
    this.sideEffects = const [],
    this.imageUrl,
    this.price = 0.0,
    this.requiresPrescription = false,
    this.barcode,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'],
      name: json['name'],
      genericName: json['genericName'],
      manufacturer: json['manufacturer'],
      dosage: json['dosage'],
      form: json['form'],
      description: json['description'],
      indications: List<String>.from(json['indications'] ?? []),
      contraindications: List<String>.from(json['contraindications'] ?? []),
      sideEffects: List<String>.from(json['sideEffects'] ?? []),
      imageUrl: json['imageUrl'],
      price: (json['price'] ?? 0.0).toDouble(),
      requiresPrescription: json['requiresPrescription'] ?? false,
      barcode: json['barcode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'genericName': genericName,
      'manufacturer': manufacturer,
      'dosage': dosage,
      'form': form,
      'description': description,
      'indications': indications,
      'contraindications': contraindications,
      'sideEffects': sideEffects,
      'imageUrl': imageUrl,
      'price': price,
      'requiresPrescription': requiresPrescription,
      'barcode': barcode,
    };
  }
}
