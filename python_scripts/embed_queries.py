from sentence_transformers import SentenceTransformer
from supabase import create_client, Client
from fastapi import FastAPI
from pydantic import BaseModel
import numpy as np
import json



url = 'https://cocmclecxanepyheygqs.supabase.co'
service_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvY21jbGVjeGFuZXB5aGV5Z3FzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjUyMjA1MiwiZXhwIjoyMDc4MDk4MDUyfQ.ZW8JOkw2A1NTbL3R9lIHMXQK5CqNe_azkwwFQBF_-HU"  # NOT the anon key
supabase: Client = create_client(url, service_key)

# models = {'all-MiniLM-L6-v2': SentenceTransformer('all-MiniLM-L6-v2'), 'all-mpnet-base-v2': SentenceTransformer('all-mpnet-base-v2'), 'bert-base-nli-mean-tokens': SentenceTransformer('bert-base-nli-mean-tokens')}
model = 'all-mpnet-base-v2'
current_model = SentenceTransformer('all-mpnet-base-v2')
app = FastAPI()

class Query(BaseModel):
    text: str


def cosine_similarity(a, b):
    return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))


@app.post("/search")
def search(query: Query):

    top_results = []

    # for model, current_model in models.items():
        # current_model = SentenceTransformer(model)
    rows = supabase.table("vendors").select(f'vendor_id, {model}').execute().data
    query_emb = current_model.encode([query.text])[0]

    scores = [cosine_similarity(query_emb, np.array(json.loads(r[f'{model}']), dtype=float)) for r in rows]

    top_results.append(sorted(zip(rows, scores), key=lambda x: x[1], reverse=True)[:4])

    return [row["vendor_id"] for model_top in top_results for row, score in model_top]




# from sentence_transformers import SentenceTransformer
# from supabase import create_client, Client
# from fastapi import FastAPI
# from fastapi.middleware.cors import CORSMiddleware
# from pydantic import BaseModel
# import numpy as np
# import json

# url = 'https://cocmclecxanepyheygqs.supabase.co'
# service_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvY21jbGVjeGFuZXB5aGV5Z3FzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjUyMjA1MiwiZXhwIjoyMDc4MDk4MDUyfQ.ZW8JOkw2A1NTbL3R9lIHMXQK5CqNe_azkwwFQBF_-HU"
# supabase: Client = create_client(url, service_key)

# model = 'all-mpnet-base-v2'
# current_model = SentenceTransformer('all-mpnet-base-v2')
# app = FastAPI()

# # Add CORS middleware
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"],  # In production, replace with specific origins like ["http://localhost:3000"]
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# class Query(BaseModel):
#     text: str


# def cosine_similarity(a, b):
#     return np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b))


# @app.post("/search")
# def search(query: Query):
#     # Fetch all vendors
#     rows = supabase.table("vendors").select(f'vendor_id, {model}').execute().data
    
#     # Encode the query
#     query_emb = current_model.encode([query.text])[0]
    
#     # Filter out rows without embeddings and calculate scores
#     valid_results = []
#     for r in rows:
#         embedding_data = r.get(model)
        
#         # Skip if embedding is None, empty, or null
#         if embedding_data is None or embedding_data == '' or embedding_data == 'null':
#             continue
            
#         try:
#             # Try to parse and convert the embedding
#             embedding = np.array(json.loads(embedding_data), dtype=float)
            
#             # Additional validation: check if embedding has the right shape
#             if embedding.size == 0:
#                 continue
                
#             # Calculate similarity
#             score = cosine_similarity(query_emb, embedding)
#             valid_results.append((r, score))
            
#         except (json.JSONDecodeError, ValueError, TypeError) as e:
#             # Skip rows with malformed embeddings
#             print(f"Skipping vendor {r.get('vendor_id')} due to error: {e}")
#             continue
    
#     # Sort by score and get top 4
#     top_results = sorted(valid_results, key=lambda x: x[1], reverse=True)[:4]
    
#     # Return vendor IDs
#     return [row["vendor_id"] for row, score in top_results]