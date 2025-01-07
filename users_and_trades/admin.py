from django.contrib import admin

# Register your models here.
from .models import User, Trade

admin.site.register(Trade)
