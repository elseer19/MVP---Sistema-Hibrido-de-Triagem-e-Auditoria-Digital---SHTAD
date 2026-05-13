# analysis/llm_evaluation.py
import csv
from sklearn.metrics import precision_recall_fscore_support, confusion_matrix

gold = []
pred = []
with open('analysis/gold_standard.csv', newline='', encoding='utf-8') as f:
    reader = csv.DictReader(f)
    for row in reader:
        gold.append(row['gold_label'])   # ex: VERDE/AMARELO/...
        pred.append(row['llm_label'])

labels = sorted(list(set(gold)))
p, r, f1, _ = precision_recall_fscore_support(gold, pred, labels=labels, average=None)
cm = confusion_matrix(gold, pred, labels=labels)

# salvar CSV resumo
import pandas as pd
df = pd.DataFrame({'label': labels, 'precision': p, 'recall': r, 'f1': f1})
df.to_csv('analysis/llm_evaluation.csv', index=False)
print(df)
