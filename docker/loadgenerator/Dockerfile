FROM python:3.11-slim

WORKDIR /app

COPY src/loadgenerator .

RUN pip install --no-cache-dir -r requirements.txt

ENV FRONTEND_ADDR=frontend:8080
ENV USERS=10

CMD ["python", "-m", "locust", "-f", "locustfile.py", "--headless"]