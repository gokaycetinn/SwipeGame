# FutSwipe Backend (FastAPI)

Bu backend, FutSwipe icin futbolcu/stadyum verilerini kaydetmek ve bu verilere gore soru uretmek icin tasarlanmistir.

## Kurulum

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Calistirma

```bash
uvicorn app.main:app --reload --port 8000
```

## Temel endpointler

- `GET /health`
- `POST /players`
- `GET /players`
- `POST /stadiums`
- `GET /stadiums`
- `POST /rules`
- `GET /rules`
- `POST /rules/seed`
- `POST /import/csv`
- `POST /questions/generate`

## Ornek istekler

### Kural tohumla

```bash
curl -X POST http://127.0.0.1:8000/rules/seed
```

### Futbolcu ekle

```bash
curl -X POST http://127.0.0.1:8000/players \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Erling",
    "last_name": "Haaland",
    "photo_url": "https://example.com/haaland.jpg",
    "country": "Norway",
    "primary_position": "forward",
    "clubs_csv": "Manchester City,Borussia Dortmund",
    "competitions_won_csv": "UEFA Champions League",
    "leagues_played_csv": "Premier League,Bundesliga"
  }'
```

### Soru uret

```bash
curl -X POST http://127.0.0.1:8000/questions/generate \
  -H "Content-Type: application/json" \
  -d '{"count": 10, "target_type": "mixed"}'
```

### CSV ile toplu veri yukle

Once su dosyalari doldur:

- `backend/data/players.csv`
- `backend/data/stadiums.csv`
- `backend/data/rules.csv`

Import islemi:

```bash
curl -X POST "http://127.0.0.1:8000/import/csv"
```

Mevcut verileri silip bastan import etmek istersen:

```bash
curl -X POST "http://127.0.0.1:8000/import/csv?clear_existing=true"
```

Donen cevabta her tablo icin `imported`, `skipped` ve `errors` alanlari gelir.

## Not

Ilk asamada sade bir kural motoru vardir. Bir sonraki adimda bunu SQL tabanli daha zengin bir kural motoruna ve zorluk dengelemesine genisletebiliriz.
