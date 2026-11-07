from django.conf import settings
from django.http import HttpResponse


class ApiCorsMiddleware:
    """Apply a small explicit CORS allowlist to API requests only."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        origin = request.headers.get("Origin")
        is_api = request.path.startswith("/api/")
        allowed = is_api and origin in settings.CORS_ALLOWED_ORIGINS

        if request.method == "OPTIONS" and is_api:
            response = HttpResponse(status=204)
        else:
            response = self.get_response(request)

        if allowed:
            response["Access-Control-Allow-Origin"] = origin
            response["Vary"] = "Origin"
            response["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
            response["Access-Control-Allow-Headers"] = "Content-Type, Authorization"
        return response
