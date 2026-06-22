void main() {
  String id = DateTime.now().millisecondsSinceEpoch.toString();
  int parsedId = int.tryParse(id) ?? id.hashCode;
  print("Parsed ID: $parsedId");
  print("32-bit ID: ${parsedId & 0x7FFFFFFF}");
}
