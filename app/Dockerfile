# -------- Build Stage --------
FROM python:3.10.7-alpine3.16 AS builder
LABEL maintainer="Anthony Mogrovejo <kdetony@ballenaroja.services>"
WORKDIR /app

# Install dependencies for system and packages Python
COPY requirements.txt . 

RUN apk add --no-cache build-base \
  && pip install --upgrade pip \
  && pip install --prefix=/install -r requirements.txt

# -------- Final Stage --------
FROM python:3.10.7-alpine3.16
LABEL maintainer="Anthony Mogrovejo <kdetony@ballenaroja.services>"
WORKDIR /app

# Copy only from builder
COPY --from=builder /install /usr/local

# Copy App Flask
COPY app.py templates/ static/ ./

#Export port 
EXPOSE 8888

#Execute application
CMD ["python3", "app.py"]
