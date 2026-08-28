# Use official Python 3.11 lightweight Linux image
FROM python:3.11-slim

# Install system dependencies including FFmpeg for audio processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libsndfile1 \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for Docker cache optimization
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create persistent media directories
RUN mkdir -p media_storage/recordings media_storage/outputs media_storage/voice_models

# Expose port 8000
EXPOSE 8000

# Start FastAPI server via Uvicorn
CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
