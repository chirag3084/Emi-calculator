# ClearEMI — Flutter + Django EMI Calculator

A mobile-first loan EMI calculator with a Flutter client and a stateless Django JSON API. The calculator reports the monthly installment, total interest and total repayment. It does not create accounts or store loan inputs.

## Project layout

```text
emi-calculator/
├── flutter_app/                 # Flutter UI, API client, result model and test
│   ├── lib/main.dart
│   ├── lib/emi_api.dart
│   ├── lib/emi_result.dart
│   └── test/emi_result_test.dart
└── backend/                     # Django API and API tests
    ├── config/                  # Django settings, routes and WSGI
    └── calculator/              # EMI calculation, CORS and tests
```

## Run the Django backend

Python 3.12 or newer is recommended.

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export DJANGO_DEBUG=True
export DJANGO_ALLOWED_HOSTS=127.0.0.1,localhost
# For Flutter Web, include the web dev origin shown by Flutter, e.g.:
export CORS_ALLOWED_ORIGINS=http://localhost:5000,http://127.0.0.1:5000
python manage.py runserver 0.0.0.0:8000
```

Health check: `GET http://127.0.0.1:8000/api/health/`.

### Run backend tests

```bash
cd backend
python manage.py test
```

### EMI endpoint

`POST /api/calculate-emi/` with JSON:

```json
{
  "principal": 5000000,
  "annual_interest_rate": 8.5,
  "tenure_months": 240
}
```

Response fields: `principal`, `annual_interest_rate`, `tenure_months`, `monthly_emi`, `total_interest`, and `total_payment`. The annual rate is a percentage (8.5 means 8.5%); tenure is in months. Inputs are bounded to principal above zero through ₹1,000,000,000, rate 0–100%, and tenure 1–600 months. Invalid input returns HTTP 400 with an `error` message.

The formula is `P × r × (1 + r)^n / ((1 + r)^n − 1)`, where `r` is the monthly rate and `n` is the number of months. When the rate is zero, EMI is `P / n`. The API uses decimal arithmetic and rounds currency to two decimal places.

## Run the Flutter client

Flutter SDK 3.19+ is required. This environment did not include Flutter, so generate the platform runner folders once with Flutter installed:

```bash
cd flutter_app
flutter create .
flutter pub get
```

Start the backend first, then launch the client with an API URL reachable from the target:

```bash
# Android emulator (10.0.2.2 maps to the development host)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# iOS simulator
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000

# Physical device: use your computer's LAN IP and allow it through the firewall
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000

# Flutter Web: use the local backend URL and allow Flutter's printed web origin in CORS
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

For Android device builds, verify that the generated `android/app/src/main/AndroidManifest.xml` includes the `android.permission.INTERNET` permission. Android may block local plain-HTTP development traffic; if needed, enable `android:usesCleartextTraffic="true"` in the app's `<application>` manifest element for development only, then remove it for release builds. For Flutter Web, set `CORS_ALLOWED_ORIGINS` to the exact origin printed by `flutter run -d chrome`.

Run Flutter checks after the SDK is available:

```bash
cd flutter_app
flutter analyze
flutter test
```

## Production notes

Set a strong `DJANGO_SECRET_KEY`, `DJANGO_DEBUG=False`, restrictive `DJANGO_ALLOWED_HOSTS`, and exact `CORS_ALLOWED_ORIGINS` values in the backend hosting environment. Terminate HTTPS at the hosting platform and do not expose Django's development server directly to the public internet; use a production WSGI server such as Gunicorn or the host's supported Django runtime. Build the mobile application with a production `API_BASE_URL` using HTTPS. Loan estimates are informational and are not a lender offer or financial advice.
