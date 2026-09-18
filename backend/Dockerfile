FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt gunicorn

COPY . ./
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

EXPOSE 8000
ENTRYPOINT ["docker-entrypoint"]
CMD ["gunicorn", "--workers", "2", "--bind", "0.0.0.0:8000", "food_delivery.wsgi:application"]
