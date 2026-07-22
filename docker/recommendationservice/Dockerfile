FROM python:3.11-slim

WORKDIR /app

COPY src/recommendationservice .

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8081

CMD ["python", "recommendation_server.py"]