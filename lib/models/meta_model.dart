class MetaModel {
  final String? text;
  final String? url;
  final String? img;

  MetaModel({this.text, this.url, this.img});

  factory MetaModel.fromJson(Map<String, dynamic> json) {
    return MetaModel(
      text: json['text']?.toString(),
      url: json['url']?.toString(),
      img: json['img']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'url': url, 'img': img};
  }
}
