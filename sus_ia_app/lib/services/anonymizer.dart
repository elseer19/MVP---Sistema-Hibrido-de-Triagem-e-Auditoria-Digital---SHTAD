// flutter_app/lib/services/anonymizer.dart
String anonymizeRelato(String texto) {
  // Remover números longos (CPF, telefone), emails e tokens óbvios
  String s = texto.replaceAll(RegExp(r'\b\d{3}\.?\d{3}\.?\d{3}\-?\d{2}\b'), '[IDENTIFICADOR]');
  s = s.replaceAll(RegExp(r'\b\d{10,}\b'), '[NUMERO]');
  s = s.replaceAll(RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w{2,}\b'), '[EMAIL]');
  // Opcional: truncar frases que contenham nomes próprios (heurística)
  s = s.replaceAll(RegExp(r'\b(Nome|Nome do paciente|Meu nome é)\b.*', caseSensitive: false), '[RETRATO_PESSOAL]');
  return s;
}
