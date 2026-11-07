import json

from django.test import SimpleTestCase, Client


class EmiApiTests(SimpleTestCase):
    def setUp(self):
        self.client = Client()

    def post_json(self, payload):
        return self.client.post(
            "/api/calculate-emi/",
            data=json.dumps(payload),
            content_type="application/json",
        )

    def test_health_endpoint(self):
        response = self.client.get("/api/health/")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "ok")

    def test_standard_loan_calculation(self):
        response = self.post_json(
            {"principal": 1000000, "annual_interest_rate": 8.5, "tenure_months": 240}
        )
        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["monthly_emi"], 8678.23)
        self.assertEqual(body["tenure_months"], 240)
        self.assertGreater(body["total_payment"], body["principal"])
        self.assertEqual(body["total_payment"], body["monthly_emi"] * body["tenure_months"])

    def test_zero_interest_uses_principal_divided_by_months(self):
        response = self.post_json(
            {"principal": 120000, "annual_interest_rate": 0, "tenure_months": 12}
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["monthly_emi"], 10000.0)
        self.assertEqual(response.json()["total_interest"], 0.0)

    def test_invalid_principal_is_rejected(self):
        response = self.post_json(
            {"principal": -1, "annual_interest_rate": 8, "tenure_months": 12}
        )
        self.assertEqual(response.status_code, 400)
        self.assertIn("error", response.json())

    def test_missing_field_is_rejected(self):
        response = self.post_json({"principal": 10000, "annual_interest_rate": 8})
        self.assertEqual(response.status_code, 400)
        self.assertIn("tenure_months", response.json()["error"])

    def test_invalid_json_is_rejected(self):
        response = self.client.post(
            "/api/calculate-emi/", data="{", content_type="application/json"
        )
        self.assertEqual(response.status_code, 400)
