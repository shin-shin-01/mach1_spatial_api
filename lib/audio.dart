class Audio {
  String id;
  String name;
  String url;

  Audio(this.id, this.name, this.url);

  static Audio fromJson(String id, dynamic json) {
    final name = json["name"] as String;
    final url = json["url"] as String;
    return Audio(id, name, url);
  }
}
