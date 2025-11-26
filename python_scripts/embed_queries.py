from sentence_transformers import SentenceTransformer
from supabase import create_client, Client
from fastapi import FastAPI
from pydantic import BaseModel
import numpy as np
import json



url = 'https://cocmclecxanepyheygqs.supabase.co'
service_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvY21jbGVjeGFuZXB5aGV5Z3FzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjUyMjA1MiwiZXhwIjoyMDc4MDk4MDUyfQ.ZW8JOkw2A1NTbL3R9lIHMXQK5CqNe_azkwwFQBF_-HU"  # NOT the anon key
supabase: Client = create_client(url, service_key)

models = ['all-MiniLM-L6-v2', 'all-mpnet-base-v2', 'bert-base-nli-mean-tokens']

app = FastAPI()

class Query(BaseModel):
    text: str


def cosine_similarity(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))


@app.post("/search")
def search(query: Query):

    top_results = []

    for model in models:
        current_model = SentenceTransformer(model)
        rows = supabase.table("vendors").select(f'vendor_id, {model}').execute().data
        query_emb = current_model.encode([query.text])[0]

        scores = [cosine_similarity(query_emb, np.array(json.loads(r[f'{model}']), dtype=float)) for r in rows]

        top_results.append(sorted(zip(rows, scores), key=lambda x: x[1], reverse=True)[:1])

    return [row["vendor_id"] for model_top in top_results for row, score in model_top]


