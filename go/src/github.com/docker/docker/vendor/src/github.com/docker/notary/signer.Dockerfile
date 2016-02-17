FROM dockersecurity/golang-softhsm2
MAINTAINER Diogo Monica "diogo@docker.com"

# CHANGE-ME: Default values for SoftHSM2 PIN and SOPIN, used to initialize the first token
ENV NOTARY_SIGNER_PIN="1234"
ENV SOPIN="1234"
ENV LIBDIR="/usr/local/lib/softhsm/"
ENV NOTARY_SIGNER_DEFAULT_ALIAS="timestamp_1"
ENV NOTARY_SIGNER_TIMESTAMP_1="testpassword"

# Install openSC and dependencies
RUN apt-get update && apt-get install -y \
    libltdl-dev \
    libpcsclite-dev \
    opensc \
    usbutils \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Initialize the SoftHSM2 token on slod 0, using PIN and SOPIN varaibles
RUN softhsm2-util --init-token --slot 0 --label "test_token" --pin $NOTARY_SIGNER_PIN --so-pin $SOPIN

ENV NOTARYPKG github.com/docker/notary
ENV GOPATH /go/src/${NOTARYPKG}/Godeps/_workspace:$GOPATH

EXPOSE 4444

# Copy the local repo to the expected go path
COPY . /go/src/github.com/docker/notary

WORKDIR /go/src/${NOTARYPKG}

# Install notary-signer
RUN go install \
    -tags pkcs11 \
    -ldflags "-w -X ${NOTARYPKG}/version.GitCommit=`git rev-parse --short HEAD` -X ${NOTARYPKG}/version.NotaryVersion=`cat NOTARY_VERSION`" \
    ${NOTARYPKG}/cmd/notary-signer


ENTRYPOINT [ "notary-signer" ]
CMD [ "-config=fixtures/signer-config-local.json" ]
