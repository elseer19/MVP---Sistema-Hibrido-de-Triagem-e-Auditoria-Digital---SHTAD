# IA-Triagem: Sistema Híbrido de Classificação de Risco para o SUS

## 📌 Apresentação e Objetivo
O presente projeto consiste em uma Prova de Conceito (PoC) para um sistema de triagem médica baseado em Inteligência Artificial e Processamento de Linguagem Natural (NLP). O objetivo central é otimizar o fluxo de pacientes em Unidades de Pronto Atendimento (UPAs) e emergências do Sistema Único de Saúde (SUS).

Através da interface de um totem de autoatendimento, o sistema coleta o relato sintomático do paciente via comando de voz e utiliza inferência de IA para aplicar as diretrizes do **Protocolo de Manchester**. Casos críticos (Vermelho, Laranja, Amarelo) são imediatamente sinalizados para a equipe de enfermagem, enquanto demandas de baixa complexidade (Verde, Azul) são direcionadas a uma fila digital, onde um Médico Auditor valida a conduta de forma assíncrona, reduzindo significativamente o tempo de espera e a superlotação física.

## 🏗️ Arquitetura do Sistema
A solução foi arquitetada sob um modelo híbrido e modular, garantindo escalabilidade e processamento em tempo real:

*   **Interface de Interação (Frontend):** Desenvolvida em **Flutter** (Dart), estruturada para funcionar como um totem de autoatendimento. Integra a biblioteca `speech_to_text` para transcrição de áudio, garantindo acessibilidade e rapidez na coleta do relato.
*   **Motor Cognitivo (IA):** O núcleo de decisão lógica utiliza a **API do Google Gemini** (modelo `gemini-3-flash-preview`). O LLM (Large Language Model) opera sob rigoroso *Prompt Engineering*, atuando como um sistema especialista fechado que mapeia o relato do paciente aos discriminadores clínicos do Protocolo de Manchester. Há mecanismos de *bypass* rígidos (ex: alerta de trauma grave) que anulam a IA e acionam o atendimento presencial imediatamente.
*   **Simulação Estocástica (Backend/Dados):** Para fins de validação da eficácia sem risco à saúde humana (em adequação às normativas de ética em pesquisa), foram desenvolvidos scripts em **Python** que geram pacientes sintéticos e simulam filas de atendimento (Modelagem de Monte Carlo).

## 🚀 Como Reproduzir e Testar (MVP)
Para executar o protótipo do totem localmente em sua máquina, siga os passos de compilação:

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/elseer19/MVP---Sistema-Hibrido-de-Triagem-e-Auditoria-Digital---SHTAD

   *Nota: Recomenda-se testar em um dispositivo físico ou emulador com suporte a entrada de microfone para validar o módulo de transcrição de voz.*

## 📊 Resultados da Simulação Computacional
O diretório `/simulacao_dados` contém os scripts Python e os *datasets* resultantes do experimento in silico desenvolvido para este projeto. 

**Análise Preliminar:**
Os dados gerados comprovam matematicamente a hipótese do estudo. A implementação do sistema híbrido demonstrou uma redução substancial no **Tempo Médio de Triagem (TMT)** da unidade de saúde simulada. Ao reter e direcionar as classificações "Verde" e "Azul" para a auditoria médica digital, a carga de trabalho presencial dos enfermeiros triadores caiu drasticamente, resultando em um ganho de agilidade crítico na identificação e acolhimento dos pacientes com risco iminente de morte.

---
**Pesquisador Responsável:** Elias Brendo Simplício de Sousa
**Categoria:** Estudante do Ensino Superior - Prêmio Jovem Cientista
