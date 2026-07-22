FROM python:3.11-slim

WORKDIR /app

COPY src/shoppingassistantservice .

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8080

CMD ["python", "shopping_assistant_server.py"]