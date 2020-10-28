FROM docker:latest

RUN apk --no-cache add curl bash

RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

RUN ibmcloud plugin install kubernetes-service

WORKDIR /

RUN mkdir /scripts
COPY scripts/run.sh /scripts/run.sh

RUN chmod 755 /scripts/run.sh