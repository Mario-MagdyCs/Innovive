FROM python:3.10

WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libxext6 \
    libxrender-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip setuptools wheel

# Copy files
COPY . .

# Install Python requirements
RUN pip install --no-cache-dir -r requirements.txt

# Expose port
EXPOSE 5000

# Run
CMD ["python", "classify.py"]
