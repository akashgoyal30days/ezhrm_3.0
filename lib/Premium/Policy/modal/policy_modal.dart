class PolicyModel {
  final String name;
  final String description;
  final String file;

  PolicyModel({
    required this.name,
    required this.description,
    required this.file,
  });

  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    return PolicyModel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      file: json['file'] ?? '',
    );
  }
}
