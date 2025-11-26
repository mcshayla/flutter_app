from sentence_transformers import SentenceTransformer
from supabase import create_client, Client


# model_one = 'all-MiniLM-L6-v2' #384
# model_two = 'all-mpnet-base-v2' #384
# model_four = 'bert-base-nli-mean-tokens' #768



url = 'https://cocmclecxanepyheygqs.supabase.co'
service_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvY21jbGVjeGFuZXB5aGV5Z3FzIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MjUyMjA1MiwiZXhwIjoyMDc4MDk4MDUyfQ.ZW8JOkw2A1NTbL3R9lIHMXQK5CqNe_azkwwFQBF_-HU"  # NOT the anon key
supabase: Client = create_client(url, service_key)

models = ['all-mpnet-base-v2', 'bert-base-nli-mean-tokens']

response = supabase.table("vendors").select(
    "vendor_id, vendor_category, vendor_name, vendor_description, vendor_price, style_keywords"
).execute()

rows = response.data

# Combine in Python
for row in rows:
    combined = (
        f"{row.get('vendor_category','')}-"
        f"{row.get('vendor_name','')}-"
        f"{row.get('vendor_description','')} Price: "
        f"{row.get('vendor_price','')} Style Words: "
        f"{row.get('style_keywords','')}"
    )
    row["combined"] = combined
print(f"length of rows: {len(rows)}")

print()
for model in models:
    current_model = SentenceTransformer(model)
    print(model)
    for row in rows:
        text = row["combined"]
        vector = current_model.encode(text).tolist()
    
        supabase.table("vendors") \
        .update({model: vector}) \
        .eq("vendor_id", row["vendor_id"]) \
        .execute()




