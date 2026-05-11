import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

const String apiKey = 'INSIRA_SUA_API_KEY_AQUI';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MVP Triagem Híbrida IA',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const TelaTriagemHibrida(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TelaTriagemHibrida extends StatefulWidget {
  const TelaTriagemHibrida({super.key});

  @override
  State<TelaTriagemHibrida> createState() => _TelaTriagemHibridaState();
}

class _TelaTriagemHibridaState extends State<TelaTriagemHibrida> {
  final _relatoController = TextEditingController();
  bool _temTrauma = false;

  bool _carregando = false;
  String _resultadoIA = 'Aguardando relato do paciente...';
  Color _corResultado = Colors.grey.shade200;

  // --- NOVAS VARIÁVEIS DE FLUXO ---
  bool _analiseFinalizada = false;
  String _orientacaoPaciente = '';

  // --- VARIÁVEIS DE RECONHECIMENTO DE VOZ ---
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (val) => print('Erro no microfone: $val'),
      onStatus: (val) => print('Status do microfone: $val'),
    );
    setState(() {});
  }

  void _listen() async {
    if (!_isListening && _speechEnabled) {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (val) => setState(() {
          _relatoController.text = val.recognizedWords;
        }),
        localeId: 'pt_BR',
      );
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

  // --- FUNÇÃO DE RESET PARA NOVO PACIENTE ---
  void _resetarTela() {
    setState(() {
      _relatoController.clear();
      _temTrauma = false;
      _resultadoIA = 'Aguardando relato do paciente...';
      _corResultado = Colors.grey.shade200;
      _analiseFinalizada = false;
      _orientacaoPaciente = '';
    });
  }

  Future<void> _analisarComIA() async {
    if (_isListening) await _speech.stop();
    setState(() => _isListening = false);

    if (_temTrauma) {
      setState(() {
        _resultadoIA = "🚨 ALERTA DE RISCO (Regra Rígida):\nPaciente relatou Trauma Grave ou Arma de fogo. Ignorando IA.";
        _corResultado = Colors.redAccent.shade100;
        _orientacaoPaciente = "DIRIJA-SE IMEDIATAMENTE À SALA VERMELHA OU CHAME UM ENFERMEIRO!";
        _analiseFinalizada = true;
      });
      return;
    }

    if (_relatoController.text.trim().isEmpty) return;

    setState(() {
      _carregando = true;
      _resultadoIA = 'O Motor Cognitivo (Gemini) está analisando o caso...';
      _corResultado = Colors.blue.shade50;
    });

    try {
      final model = GenerativeModel(
        model: 'gemini-3-flash-preview', 
        apiKey: apiKey,
        systemInstruction: Content.system('''
          Você é um Sistema Especialista Híbrido de Triagem Médica para o SUS.
          Sua função é analisar o relato do paciente e classificar estritamente usando o Protocolo de Manchester.
          
          Regras de Classificação (Manchester):
          - VERMELHO (Emergência): Risco imediato. Ex: Sangramento massivo, dor no peito intensa. (Destino: Médico Presencial - Sala Vermelha)
          - LARANJA (Muito Urgente): Risco significativo. Ex: Falta de ar moderada a grave. (Destino: Médico Presencial)
          - AMARELO (Urgente): Condição grave, mas estável. Ex: Dor intensa localizada, febre alta. (Destino: Médico Presencial)
          - VERDE (Pouco Urgente): Casos menos graves. Ex: Dor moderada, resfriado, vômito sem desidratação. (Destino: Auditor Digital)
          - AZUL (Não Urgente): Casos simples. Ex: Dor crônica leve, troca de receita, sintomas leves antigos. (Destino: Auditor Digital)

          Responda com o seguinte formato:
          Classificação: [Apenas uma cor: VERMELHO, LARANJA, AMARELO, VERDE ou AZUL]
          Destino: [Auditor Digital ou Médico Presencial]
          Diagnóstico Presuntivo: [Sua análise]
          Sugestão: [Ação recomendada]
        '''),
      );

      final prompt = 'Relato do paciente: "${_relatoController.text}"';
      final response = await model.generateContent([Content.text(prompt)]);

      setState(() {
        _resultadoIA = response.text ?? 'Erro na geração da IA.';
        _analiseFinalizada = true; // Define que a IA terminou

        // Define a cor e a orientação para o paciente baseada na resposta da IA
        if (_resultadoIA.contains('VERMELHO')) {
          _corResultado = Colors.red.shade100;
          _orientacaoPaciente = "🚨 EMERGÊNCIA: DIRIJA-SE IMEDIATAMENTE À SALA VERMELHA!";
        } else if (_resultadoIA.contains('LARANJA')) {
          _corResultado = Colors.orange.shade100;
          _orientacaoPaciente = "⚠️ MUITO URGENTE: DIRIJA-SE AO BALCÃO DE ATENDIMENTO AGORA!";
        } else if (_resultadoIA.contains('AMARELO')) {
          _corResultado = Colors.yellow.shade100;
          _orientacaoPaciente = "⏳ URGENTE: AGUARDE NA RECEPÇÃO. SEU ATENDIMENTO SERÁ PRIORIZADO.";
        } else if (_resultadoIA.contains('VERDE')) {
          _corResultado = Colors.green.shade100;
          _orientacaoPaciente = "✅ POUCO URGENTE: AGUARDE. SEU CASO FOI ENCAMINHADO AO AUDITOR DIGITAL (MAIS RÁPIDO).";
        } else if (_resultadoIA.contains('AZUL')) {
          _corResultado = Colors.blue.shade100;
          _orientacaoPaciente = "🔵 NÃO URGENTE: AGUARDE. SEU CASO FOI ENCAMINHADO AO AUDITOR DIGITAL.";
        } else {
          _corResultado = Colors.grey.shade200;
          _orientacaoPaciente = "CLASSIFICAÇÃO INDEFINIDA. POR FAVOR, PROCURE A RECEPÇÃO.";
        }
      });
    } catch (e) {
      setState(() {
        _resultadoIA = 'Erro de conexão: $e';
        _corResultado = Colors.red.shade100;
        _orientacaoPaciente = "ERRO NO SISTEMA. POR FAVOR, DIRIJA-SE À RECEPÇÃO.";
        _analiseFinalizada = true;
      });
    } finally {
      setState(() {
        _carregando = false;
      });
    }
  }

      @override void _solicitarAtendimentoPresencial() async {
     // Se o microfone estiver ligado, desliga
      if (_isListening) await _speech.stop();
    
      setState(() {
      _isListening = false;
      _resultadoIA = "⚠️ Bypass de IA: Paciente optou por não realizar a triagem digital e solicitou atendimento presencial.";
      _corResultado = Colors.orange.shade100; // Laranja para indicar que precisa de triagem humana
      _orientacaoPaciente = "DIRIJA-SE À RECEPÇÃO PARA REALIZAR A TRIAGEM COM UM ENFERMEIRO.";
      _analiseFinalizada = true;
    });
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Totem - Fale seus sintomas', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // SÓ MOSTRA O CAMPO DE TEXTO E MICROFONE SE A ANÁLISE NÃO FOI FINALIZADA
            if (!_analiseFinalizada) ...[
              const Text(
                'Aperte o microfone e diga o que está sentindo:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              

              TextField(
                controller: _relatoController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Aguardando o seu relato...',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    iconSize: 40,
                    color: _isListening ? Colors.red : Colors.indigo,
                    icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                    onPressed: _listen,
                  ),
                ),
              ),
              if (_isListening) 
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('Ouvindo...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                ),
              const SizedBox(height: 15),

              SwitchListTile(
                title: const Text('Ocorrência de Trauma Grave?'),
                value: _temTrauma,
                activeThumbColor: Colors.red,
                onChanged: (val) => setState(() => _temTrauma = val),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _carregando ? null : _analisarComIA,
                icon: _carregando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check_circle),
                label: Text(_carregando ? 'PROCESSANDO...' : 'CONCLUIR RELATO'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
              // --- NOVO BOTÃO DE ATENDIMENTO PRESENCIAL ---
              TextButton.icon(
                onPressed: _carregando ? null : _solicitarAtendimentoPresencial,
                icon: const Icon(Icons.support_agent, size: 28),
                label: const Text(
                  'PULAR IA E SOLICITAR ATENDIMENTO PRESENCIAL',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.all(15),
                  foregroundColor: Colors.indigo, // Mesma paleta do seu tema
                ),
              ),
            ],

            // --- TELA DE RESULTADO (PÓS-ANÁLISE) ---
            if (_analiseFinalizada) ...[
              const Icon(Icons.info_outline, size: 60, color: Colors.indigo),
              const SizedBox(height: 10),
              
              // Orientação principal para o paciente (O que ele deve fazer agora)
              Text(
                _orientacaoPaciente,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 30),

              // Card técnico (Apenas para o professor/jurado ver como a IA pensou)
              const Text('Dados enviados ao painel (Visualização técnica):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 5),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _corResultado,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black12),
                ),
                child: Text(
                  _resultadoIA,
                  style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 40),

              // Botão para resetar o Totem para o próximo paciente da fila
              ElevatedButton.icon(
                onPressed: _resetarTela,
                icon: const Icon(Icons.home),
                label: const Text('CONCLUIR ATENDIMENTO (PRÓXIMO PACIENTE)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Colors.teal, // Cor diferente para indicar finalização
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}