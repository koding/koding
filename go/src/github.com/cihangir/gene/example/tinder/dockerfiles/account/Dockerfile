# Start from a Debian image with the latest version of Go installed
# and a workspace (GOPATH) configured at /go.
FROM golang

# Copy the local package files to the container's workspace.
ADD . /go/src

# Build the outyet command inside the container.
# (You may fetch or manage dependencies here,
# either manually or with a tool like "godep".)

RUN go install ./bin/account

# Run the outyet command by default when the container starts.
ENTRYPOINT /go/bin/account

# Document that the service listens on port 8080.
# EXPOSE 8080
# TODO make this configurable

# to build the docker machine
# docker build -t account -f ./bin/dockerfiles/account/Dockerfile ./src/

# to run the built docker machine
# docker run -it account
