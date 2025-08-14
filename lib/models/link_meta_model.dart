class LinkMetaModel {
  final String? text;
  final String? url;
  final String? img;

  LinkMetaModel({this.text, this.url, this.img});

  factory LinkMetaModel.fromJson(Map<String, dynamic> json) {
    return LinkMetaModel(
      text: json['text']?.toString(),
      url: json['url']?.toString(),
      img: json['img']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'url': url, 'img': img};
  }
}
