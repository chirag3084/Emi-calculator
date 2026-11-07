from django.contrib import admin
from django.urls import path

from calculator.views import calculate_emi, health

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/health/", health, name="health"),
    path("api/calculate-emi/", calculate_emi, name="calculate-emi"),
]
