# FutSwipe Backend (Dataset-First)

Bu backend, buyuk futbol dataset'lerini (FIFA/European Soccer gibi) otomatik temizleyip oyuna aktarmak icin tasarlandi.

## Kurulum

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Calistirma

```bash
python3 -m uvicorn app.main:app --reload --port 8000
```

## Hedef Veri Formati

Temizlenmis oyuncu dataset'i su kolonlara indirgenir:

- `name`
- `nationality`
- `club`
- `position`
- `age`
- `image_url` (pipeline tarafindan otomatik doldurulur)

## Dataset Pipeline

### 1) Raw dataset indir

Direkt CSV linkin varsa:

```bash
python3 backend/scripts/download_dataset.py \
  --url "<DIRECT_CSV_URL>" \
  --out backend/data/raw/fifa_players.csv
```

Alternatif olarak CSV'yi elle indirip `backend/data/raw/` altina koyabilirsin.

### 2) Temizle (sadece gerekli kolonlar)

```bash
python3 backend/scripts/clean_players_csv.py \
  --in backend/data/raw/fifa_players.csv \
  --out backend/data/players_clean.csv
```

### 3) Gorselleri otomatik cek

Varsayilan siralama:

- Wikipedia Summary API (thumbnail)
- Wikimedia Commons API (search fallback)

```bash
python3 backend/scripts/enrich_player_images.py \
  --in backend/data/players_clean.csv \
  --out backend/data/players_enriched.csv \
  --limit 0
```

Not: Hizli deneme icin `--limit 500` gibi bir deger kullanabilirsin.

### 4) Backend'e import et

```bash
python3 -m uvicorn app.main:app --reload --port 8000
```

```bash
python3 -c "import urllib.request; req=urllib.request.Request('http://127.0.0.1:8000/import/players/csv?clear_existing=true', method='POST'); print(urllib.request.urlopen(req).read().decode())"
```

## Tek Komut Pipeline

```bash
python3 backend/scripts/run_dataset_pipeline.py \
  --raw backend/data/raw/fifa_players.csv \
  --image-limit 1000
```

Bu komut su ciktilari uretir:

- `backend/data/players_clean.csv`
- `backend/data/players_enriched.csv`

## Temel Endpointler

- `GET /health`
- `POST /players`
- `GET /players`
- `POST /import/players/csv`
- `POST /rules/seed`
- `POST /questions/generate`

## Ornek Player POST

```bash
curl -X POST http://127.0.0.1:8000/players \
  -H "Content-Type: application/json" \
  -d '{
    "full_name": "Erling Haaland",
    "nationality": "Norway",
    "club": "Manchester City",
    "position": "ST",
    "age": 24,
    "photo_url": "https://example.com/haaland.jpg"
  }'
```
