#!/usr/bin/env bash
set -e
BASE="http://45.12.111.55:3001/api"
TODAY=$(date +%Y-%m-%d)

echo "=== MedCare seed script ==="

# ── 1. Login ──────────────────────────────────────────────────────────────────
echo "→ Logging in..."
TOKEN=$(curl -s -X POST "$BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"doctor@medcare.ua","password":"password123"}' \
  | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo "❌ Login failed. Check credentials or server."
  exit 1
fi
echo "✅ Token acquired"
AUTH="Authorization: Bearer $TOKEN"

# ── 2. Fetch doctors & patients ───────────────────────────────────────────────
echo "→ Fetching doctors..."
DOCTORS=$(curl -s "$BASE/doctors" -H "$AUTH")
D1=$(echo "$DOCTORS" | grep -o '"id":"[^"]*"' | sed -n '1p' | cut -d'"' -f4)
D2=$(echo "$DOCTORS" | grep -o '"id":"[^"]*"' | sed -n '2p' | cut -d'"' -f4)
D3=$(echo "$DOCTORS" | grep -o '"id":"[^"]*"' | sed -n '3p' | cut -d'"' -f4)
echo "  D1=$D1  D2=$D2  D3=$D3"

echo "→ Fetching patients..."
PATIENTS=$(curl -s "$BASE/patients" -H "$AUTH")
P1=$(echo "$PATIENTS" | grep -o '"id":"[^"]*"' | sed -n '1p' | cut -d'"' -f4)
P2=$(echo "$PATIENTS" | grep -o '"id":"[^"]*"' | sed -n '2p' | cut -d'"' -f4)
P3=$(echo "$PATIENTS" | grep -o '"id":"[^"]*"' | sed -n '3p' | cut -d'"' -f4)
P4=$(echo "$PATIENTS" | grep -o '"id":"[^"]*"' | sed -n '4p' | cut -d'"' -f4)
P5=$(echo "$PATIENTS" | grep -o '"id":"[^"]*"' | sed -n '5p' | cut -d'"' -f4)
echo "  P1=$P1  P2=$P2  P3=$P3"

if [ -z "$P1" ] || [ -z "$D1" ]; then
  echo "❌ No patients or doctors found. Run the backend seed first."
  exit 1
fi

# ── 3. Appointments ───────────────────────────────────────────────────────────
echo "→ Creating appointments..."
make_appt() {
  curl -s -X POST "$BASE/appointments" -H "$AUTH" -H "Content-Type: application/json" \
    -d "{\"patientId\":\"$1\",\"doctorId\":\"$2\",\"startTime\":\"${TODAY}T$3:00.000Z\",\"endTime\":\"${TODAY}T$4:00.000Z\",\"reason\":\"$5\"}" > /dev/null
}
make_appt "$P1" "$D1" "07:00" "07:30" "repeat"
make_appt "$P2" "$D2" "07:30" "08:00" "primary"
make_appt "$P3" "$D3" "08:00" "08:30" "primary"
make_appt "$P4" "$D1" "09:00" "09:30" "preventive"
make_appt "$P5" "$D2" "10:00" "10:30" "repeat"
make_appt "$P1" "$D2" "11:00" "11:30" "repeat"
make_appt "$P2" "$D1" "12:00" "12:30" "primary"
echo "  ✅ 7 appointments"

# ── 4. Lab tests ──────────────────────────────────────────────────────────────
echo "→ Creating lab tests..."
make_lab() {
  curl -s -X POST "$BASE/lab-tests" -H "$AUTH" -H "Content-Type: application/json" \
    -d "{\"patientId\":\"$1\",\"testName\":\"$2\",\"result\":\"$3\",\"status\":\"$4\",\"notes\":\"$5\"}" > /dev/null
}
make_lab "$P1" "Загальний аналіз крові" "Гемоглобін 138 г/л, Лейкоцити 6.2×10⁹/л" "completed" "Норма"
make_lab "$P1" "Глюкоза крові" "5.4 ммоль/л" "completed" "В нормі"
make_lab "$P2" "Загальний аналіз сечі" "Питома вага 1.018, Білок відсутній" "completed" "Без патології"
make_lab "$P2" "Ліпідний профіль" "ЗХС 5.8, ЛПНЩ 3.6, ЛПВЩ 1.2" "completed" "Помірна гіперхолестеринемія"
make_lab "$P3" "МРТ шийного відділу" "Протрузія С5-С6 2мм" "completed" "Направлення до нейрохірурга"
make_lab "$P3" "Загальний аналіз крові" "Гемоглобін 125 г/л, ШОЕ 18" "completed" "Легка анемія"
make_lab "$P4" "ЕКГ" "Синусовий ритм, ЧСС 72/хв" "completed" "Норма"
make_lab "$P4" "Тиреотропний гормон (ТТГ)" "В очікуванні" "pending" ""
make_lab "$P5" "HbA1c" "7.2%" "completed" "Цукровий діабет під контролем"
make_lab "$P5" "Загальний аналіз крові" "В очікуванні" "pending" "Повторний"
echo "  ✅ 10 lab tests"

# ── 5. Prescriptions ──────────────────────────────────────────────────────────
echo "→ Creating prescriptions..."
make_rx() {
  curl -s -X POST "$BASE/prescriptions" -H "$AUTH" -H "Content-Type: application/json" \
    -d "{\"patientId\":\"$1\",\"medicationName\":\"$2\",\"dosage\":\"$3\",\"instruction\":\"$4\",\"status\":\"active\"}" > /dev/null
}
make_rx "$P1" "Амлодипін 5мг"       "1 таб."     "1 р/день вранці, 30 днів"
make_rx "$P1" "Лозартан 50мг"       "1 таб."     "1 р/день ввечері, 30 днів"
make_rx "$P2" "Парацетамол 500мг"   "1-2 таб."   "До 3 р/день при температурі, 5 днів"
make_rx "$P2" "Омепразол 20мг"      "1 капс."    "1 р/день до їжі, 14 днів"
make_rx "$P3" "Диклофенак 50мг"     "1 таб."     "2 р/день після їжі, 7 днів"
make_rx "$P3" "Пірацетам 400мг"     "2 капс."    "3 р/день, 30 днів"
make_rx "$P4" "Левотироксин 50мкг"  "1 таб."     "1 р/день натщесерце, постійно"
make_rx "$P5" "Метформін 500мг"     "1 таб."     "2 р/день під час їжі, постійно"
make_rx "$P5" "Аторвастатин 20мг"   "1 таб."     "1 р/день ввечері, постійно"
echo "  ✅ 9 prescriptions"

echo ""
echo "=== ✅ Seed complete! ==="
