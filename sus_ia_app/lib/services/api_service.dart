// flutter_app/lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'anonymizer.dart';

Future<Map<String,dynamic>> enviarRelatoParaLLM(String relato) async {
  final anon = anonymizeRelato(relato);
  final payload = {
    'session_token': DateTime.now().millisecondsSinceEpoch.toString(), // token temporário
    'relato_despersonalizado': anon,
    'metadata': {'device': 'totem_v1', 'locale': 'pt_BR'}
  };

  final resp = await http.post(
    Uri.parse(Config.LLM_ENDPOINT),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${Config.LLM_API_KEY}'
    },
    body: jsonEncode(payload),
  );

  if (resp.statusCode == 200) {
    return jsonDecode(resp.body);
  } else {
    throw Exception('LLM API error: ${resp.statusCode}');
  }
}
