# analysis/run_replications.py
import os
import json
import random
import math
import statistics
from statistics import mean
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import csv
from datetime import datetime

# ---------- CONFIGURAÇÃO ----------
SEED = 42
N_PATIENTS = 1000
N_REPLICATES = 500
OUTPUT_DIR = "analysis/results"
os.makedirs(OUTPUT_DIR, exist_ok=True)
random.seed(SEED)
np.random.seed(SEED)

# Probabilidades e parâmetros
P_LEVE = 0.70
P_PREFERE_BASE = 0.20

# Tempos médios (minutos) por cor e desvios (ajuste conforme justificativa clínica)
# Valores representam o tempo médio no Cenário A (tradicional) e Cenário B (híbrido)
TIMES = {
    'VERMELHO': {'trad_mean': 20,  'trad_sd': 5,  'hib_mean': 10,  'hib_sd': 3},
    'LARANJA':  {'trad_mean': 30,  'trad_sd': 8,  'hib_mean': 12,  'hib_sd': 4},
    'AMARELO':  {'trad_mean': 60,  'trad_sd': 15, 'hib_mean': 20,  'hib_sd': 6},
    'VERDE':    {'trad_mean': 180, 'trad_sd': 40, 'hib_mean': 8,   'hib_sd': 2},
    'AZUL':     {'trad_mean': 240, 'trad_sd': 50, 'hib_mean': 6,   'hib_sd': 1.5},
}

# Sintomas para geração
SINTOMAS_LEVES = ['Garganta','Costas','Nenhuma','Mialgia','Tosse','Coriza']
SINTOMAS_GRAVES = ['Coração','Rins','Abdome','Cabeça','Falta de Ar','Desmaio']

# ---------- GERAÇÃO DE PACIENTES ----------
def gerar_paciente():
    idade = int(max(1, min(random.gauss(40, 20), 95)))
    tem_trauma = random.random() < 0.05
    tem_sangramento = random.random() < 0.10
    oxigenio = random.triangular(85, 100, 97)
    # escolher sintoma com probabilidade condicional
    if tem_trauma or oxigenio < 92 or random.random() < 0.15:
        dor = random.choice(SINTOMAS_GRAVES)
    else:
        dor = random.choice(SINTOMAS_LEVES)
    prefere_presencial = random.random() < P_PREFERE_BASE
    return {
        'idade': idade,
        'tem_trauma': tem_trauma,
        'tem_sangramento': tem_sangramento,
        'oxigenio': oxigenio,
        'dor_principal': dor,
        'prefere_presencial': prefere_presencial
    }

# ---------- CLASSIFICAÇÃO (Motor Simbólico) ----------
def classificar_paciente(p):
    # Ordem: VERMELHO > LARANJA > AMARELO > VERDE > AZUL
    if p['oxigenio'] < 90 or p['dor_principal'] == 'Falta de Ar' or p['tem_trauma']:
        return 'VERMELHO'
    if p['dor_principal'] == 'Coração':
        return 'LARANJA'
    if p['tem_sangramento'] or p['dor_principal'] == 'Rins' or p['idade'] >= 65:
        return 'AMARELO'
    if p['dor_principal'] in ['Garganta','Costas','Mialgia','Tosse']:
        return 'VERDE'
    return 'AZUL'

# ---------- SIMULAÇÃO DE UM RUN ----------
def run_once(n=N_PATIENTS):
    pacientes = [gerar_paciente() for _ in range(n)]
    tempos_trad = []
    tempos_hib = []
    counts_by_color = {c:0 for c in TIMES.keys()}
    hib_counts = {c:0 for c in TIMES.keys()}
    trad_times_by_color = {c:[] for c in TIMES.keys()}
    hib_times_by_color = {c:[] for c in TIMES.keys()}

    for p in pacientes:
        cor = classificar_paciente(p)
        counts_by_color[cor] += 1

        # Cenário A (tradicional)
        t_trad = max(1, random.gauss(TIMES[cor]['trad_mean'], TIMES[cor]['trad_sd']))
        tempos_trad.append(t_trad)
        trad_times_by_color[cor].append(t_trad)

        # Cenário B (híbrido)
        # Graves (VERMELHO, LARANJA, AMARELO) sempre vão para presencial no modelo híbrido,
        # mas com tempos reduzidos; VERDE/AZUL podem ir para auditoria ou presencial por preferência.
        if cor in ['VERMELHO','LARANJA','AMARELO']:
            t_hib = max(1, random.gauss(TIMES[cor]['hib_mean'], TIMES[cor]['hib_sd']))
            tempos_hib.append(t_hib)
            hib_times_by_color[cor].append(t_hib)
            hib_counts[cor] += 1
        else:
            if p['prefere_presencial']:
                t_hib = max(1, random.gauss(TIMES[cor]['trad_mean']*0.25, TIMES[cor]['trad_sd']*0.5))  # presencial mais rápido
                tempos_hib.append(t_hib)
                hib_times_by_color[cor].append(t_hib)
            else:
                t_hib = max(1, random.gauss(TIMES[cor]['hib_mean'], TIMES[cor]['hib_sd']))
                tempos_hib.append(t_hib)
                hib_times_by_color[cor].append(t_hib)
                hib_counts[cor] += 1

    summary = {
        'media_trad': mean(tempos_trad),
        'media_hib': mean(tempos_hib),
        'counts_by_color': counts_by_color,
        'hib_counts': hib_counts,
        'trad_times_by_color': {k: mean(v) if v else None for k,v in trad_times_by_color.items()},
        'hib_times_by_color': {k: mean(v) if v else None for k,v in hib_times_by_color.items()},
    }
    return summary

# ---------- REPETIÇÕES E AGREGAÇÃO ----------
def replicate_and_aggregate(n_reps=N_REPLICATES):
    runs = [run_once() for _ in range(n_reps)]
    medias_trad = [r['media_trad'] for r in runs]
    medias_hib = [r['media_hib'] for r in runs]
    diffs = [a-b for a,b in zip(medias_trad, medias_hib)]

    # agregados por cor
    colors = list(TIMES.keys())
    counts_matrix = {c: [r['counts_by_color'][c] for r in runs] for c in colors}
    hib_matrix = {c: [r['hib_counts'][c] for r in runs] for c in colors}
    trad_time_matrix = {c: [r['trad_times_by_color'][c] for r in runs if r['trad_times_by_color'][c] is not None] for c in colors}
    hib_time_matrix = {c: [r['hib_times_by_color'][c] for r in runs if r['hib_times_by_color'][c] is not None] for c in colors}

    def ic95(arr):
        return (float(np.percentile(arr,2.5)), float(np.percentile(arr,97.5)))

    summary = {
        'params': {'seed': SEED, 'n_patients': N_PATIENTS, 'n_replicates': N_REPLICATES, 'p_leve': P_LEVE, 'p_prefere_presencial': P_PREFERE_BASE},
        'media_trad_mean': float(np.mean(medias_trad)),
        'media_trad_ic95': ic95(medias_trad),
        'media_hib_mean': float(np.mean(medias_hib)),
        'media_hib_ic95': ic95(medias_hib),
        'diff_mean': float(np.mean(diffs)),
        'diff_ic95': ic95(diffs),
        'counts_by_color_mean': {c: float(np.mean(counts_matrix[c])) for c in colors},
        'counts_by_color_ic95': {c: ic95(counts_matrix[c]) for c in colors},
        'hib_by_color_mean': {c: float(np.mean(hib_matrix[c])) for c in colors},
        'hib_by_color_ic95': {c: ic95(hib_matrix[c]) for c in colors},
        'trad_time_by_color_mean': {c: float(np.mean(trad_time_matrix[c])) if trad_time_matrix[c] else None for c in colors},
        'hib_time_by_color_mean': {c: float(np.mean(hib_time_matrix[c])) if hib_time_matrix[c] else None for c in colors},
        'timestamp': datetime.utcnow().isoformat() + 'Z'
    }
    # save per-run raw if needed
    with open(os.path.join(OUTPUT_DIR,'summary.json'),'w') as f:
        json.dump(summary, f, indent=2)
    return summary, medias_trad, medias_hib, diffs

# ---------- PLOTS ----------
def make_plots(medias_trad, medias_hib, diffs):
    sns.set(style="whitegrid")
    plt.figure(figsize=(8,6))
    sns.boxplot(data=[medias_trad, medias_hib], palette=["#d62728","#2ca02c"])
    plt.xticks([0,1], ['Tradicional','Híbrido'])
    plt.ylabel('Lead Time (min)')
    plt.title('Distribuição do Lead Time por Cenário (por replicação)')
    plt.savefig(os.path.join(OUTPUT_DIR,'leadtime_boxplot.png'), dpi=150)
    plt.close()

    plt.figure(figsize=(8,6))
    sns.histplot(diffs, kde=True, color="#1f77b4")
    plt.axvline(np.mean(diffs), color='red', linestyle='--', label=f'Média {np.mean(diffs):.1f} min')
    plt.xlabel('Redução do Lead Time (min)')
    plt.title('Distribuição da Redução do Lead Time (bootstrap)')
    plt.legend()
    plt.savefig(os.path.join(OUTPUT_DIR,'diff_hist.png'), dpi=150)
    plt.close()

# ---------- CSV POR COR (métricas) ----------
def save_color_table(summary):
    csv_path = os.path.join(OUTPUT_DIR,'metrics_by_color.csv')
    colors = list(TIMES.keys())
    with open(csv_path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.writer(f)
        writer.writerow(['color','count_mean','count_ic95_lo','count_ic95_hi','hib_mean','hib_ic95_lo','hib_ic95_hi','trad_time_mean','hib_time_mean'])
        for c in colors:
            cm = summary['counts_by_color_mean'][c]
            ci = summary['counts_by_color_ic95'][c]
            hm = summary['hib_by_color_mean'][c]
            hi = summary['hib_by_color_ic95'][c]
            tt = summary['trad_time_by_color_mean'][c]
            ht = summary['hib_time_by_color_mean'][c]
            writer.writerow([c, cm, ci[0], ci[1], hm, hi[0], hi[1], tt, ht])
    return csv_path

# ---------- MAIN ----------
if __name__ == "__main__":
    print("Iniciando replicações...")
    summary, medias_trad, medias_hib, diffs = replicate_and_aggregate()
    make_plots(medias_trad, medias_hib, diffs)
    csv_path = save_color_table(summary)
    print("Resultados salvos em:", OUTPUT_DIR)
    print("Resumo (exemplo):")
    print(f"Tempo Médio Tradicional: {summary['media_trad_mean']:.1f} min (IC95 {summary['media_trad_ic95']})")
    print(f"Tempo Médio Híbrido: {summary['media_hib_mean']:.1f} min (IC95 {summary['media_hib_ic95']})")
    print(f"Redução média: {summary['diff_mean']:.1f} min (IC95 {summary['diff_ic95']})")
    print("Métricas por cor salvas em:", csv_path)
