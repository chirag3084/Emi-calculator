import json
from decimal import Decimal, InvalidOperation, ROUND_HALF_UP, localcontext

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_GET, require_POST

CENT = Decimal("0.01")


def _decimal(value, field_name):
    try:
        result = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        raise ValueError(f"{field_name} must be a number.")
    if not result.is_finite():
        raise ValueError(f"{field_name} must be a finite number.")
    return result


@require_GET
def health(_request):
    return JsonResponse({"status": "ok", "service": "emi-calculator-api"})


@csrf_exempt
@require_POST
def calculate_emi(request):
    try:
        payload = json.loads(request.body or b"{}")
        if not isinstance(payload, dict):
            raise ValueError("Request body must be a JSON object.")
        required_fields = ("principal", "annual_interest_rate", "tenure_months")
        missing_fields = [field for field in required_fields if field not in payload]
        if missing_fields:
            raise ValueError(f"{missing_fields[0]} is required.")
        principal = _decimal(payload.get("principal"), "principal")
        annual_rate = _decimal(payload.get("annual_interest_rate"), "annual_interest_rate")
        tenure_value = _decimal(payload.get("tenure_months"), "tenure_months")
        if tenure_value != tenure_value.to_integral_value():
            raise ValueError("tenure_months must be a whole number.")
        tenure_months = int(tenure_value)
    except (json.JSONDecodeError, UnicodeDecodeError):
        return JsonResponse({"error": "Request body must contain valid JSON."}, status=400)
    except (ValueError, TypeError, OverflowError) as exc:
        return JsonResponse({"error": str(exc)}, status=400)

    if principal <= 0 or principal > Decimal("1000000000"):
        return JsonResponse({"error": "principal must be greater than 0 and no more than 1,000,000,000."}, status=400)
    if annual_rate < 0 or annual_rate > Decimal("100"):
        return JsonResponse({"error": "annual_interest_rate must be between 0 and 100."}, status=400)
    if tenure_months < 1 or tenure_months > 600:
        return JsonResponse({"error": "tenure_months must be between 1 and 600."}, status=400)

    principal = principal.quantize(CENT, rounding=ROUND_HALF_UP)
    if principal <= 0:
        return JsonResponse({"error": "principal must be at least 0.01."}, status=400)
    monthly_rate = annual_rate / Decimal("1200")
    with localcontext() as context:
        context.prec = 40
        if monthly_rate == 0:
            exact_emi = principal / Decimal(tenure_months)
        else:
            factor = (Decimal("1") + monthly_rate) ** tenure_months
            exact_emi = principal * monthly_rate * factor / (factor - Decimal("1"))
        emi = exact_emi.quantize(CENT, rounding=ROUND_HALF_UP)
        total_payment = (emi * tenure_months).quantize(CENT, rounding=ROUND_HALF_UP)
        total_interest = (total_payment - principal).quantize(CENT, rounding=ROUND_HALF_UP)

    return JsonResponse(
        {
            "principal": float(principal.quantize(CENT, rounding=ROUND_HALF_UP)),
            "annual_interest_rate": float(annual_rate),
            "tenure_months": tenure_months,
            "monthly_emi": float(emi),
            "total_interest": float(total_interest),
            "total_payment": float(total_payment),
        }
    )
