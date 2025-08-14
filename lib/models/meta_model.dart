class MetaModel {
  final String? title;
  final String? description;
  final String? image;

  MetaModel({this.title, this.description, this.image});

  factory MetaModel.fromJson(Map<String, dynamic> json) {
    return MetaModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'description': description, 'img': description};
  }
}
