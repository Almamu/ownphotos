FROM python:3.5
MAINTAINER Alexis Maiquez <almamu@almamu.com>

ENV MAPZEN_API_KEY mapzen-XXXX
ENV MAPBOX_API_KEY mapbox-XXXX
ENV ALLOWED_HOSTS=*

RUN mkdir /root/app
WORKDIR /root/app

# install cmake and build-essentials
RUN apt-get update && apt-get install -y cmake build-essential nginx

COPY . /root/app

# download places365 requirements
WORKDIR /root/app/api/places365
RUN wget https://s3.eu-central-1.amazonaws.com/ownphotos-deploy/places365_model.tar.gz
RUN tar xf places365_model.tar.gz

# download im2txt requirements
WORKDIR /root/app/api/im2txt
RUN wget https://s3.eu-central-1.amazonaws.com/ownphotos-deploy/im2txt_model.tar.gz
RUN tar xf im2txt_model.tar.gz
RUN wget https://s3.eu-central-1.amazonaws.com/ownphotos-deploy/im2txt_data.tar.gz
RUN tar xf im2txt_data.tar.gz

WORKDIR /root/app

# install prerequirements
RUN pip install -r prerequirements.txt
# install requirements
RUN pip install -r requirements.txt

RUN python -m spacy download en_core_web_sm

# cleanup installed packages
RUN apt-get remove --purge -y cmake git && rm -rf /var/lib/apt/lists/*

# Application admin creds
ENV ADMIN_EMAIL admin@dot.com
ENV ADMIN_USERNAME admin
ENV ADMIN_PASSWORD changeme

# Django key. CHANGEME
ENV SECRET_KEY supersecretkey
# Until we serve media files properly (django dev server doesn't serve media files with with debug=false)
ENV DEBUG true

# Database connection info
ENV DB_BACKEND postgresql
ENV DB_NAME ownphotos
ENV DB_USER ownphotos
ENV DB_PASS ownphotos
ENV DB_HOST database
ENV DB_PORT 5432

ENV BACKEND_HOST localhost
ENV FRONTEND_HOST localhost

# REDIS location
ENV REDIS_HOST redis
ENV REDIS_PORT 11211

# Timezone
ENV TIME_ZONE UTC

EXPOSE 80

# run bash for now
ENTRYPOINT ./entrypoint.sh