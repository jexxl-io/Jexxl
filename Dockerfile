# Use an official Python runtime as a parent image
FROM python:3.9.19-slim-bullseye

# Set the working directory in the container
WORKDIR /app

# Copy requirements.txt separately to leverage Docker cache
COPY dockerpy-requirements.txt .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r dockerpy-requirements.txt

# Copy the current directory contents into the container at /app
COPY . .

# Run init script
CMD ["python", "./initdb.py"]