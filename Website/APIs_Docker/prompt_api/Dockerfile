FROM python:3.10

WORKDIR /app

# Copy this API code and the generator module
COPY . .
COPY ../DIY_Text_Generation ./DIY_Text_Generation

# Make the module importable
ENV PYTHONPATH="${PYTHONPATH}:/app/DIY_Text_Generation"

RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5001

CMD ["python", "prompt_api.py"]
