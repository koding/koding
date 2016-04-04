package dockerfiles

// DockerfileTemplate holds the template for Dockerfile
var DockerfileTemplate = `# Start from a Debian image with the latest version of Go installed
# and a workspace (GOPATH) configured at /go.
FROM golang

# Copy the local package files to the container's workspace.
ADD . /go/src

# Build the outyet command inside the container.
# (You may fetch or manage dependencies here,
# either manually or with a tool like "godep".)

RUN go install {{.Settings.CMDPath}}{{ToLower .Schema.Title}}

# Run the outyet command by default when the container starts.
ENTRYPOINT /go/bin/{{ToLower .Schema.Title}}

# Document that the service listens on port 8080.
# EXPOSE 8080
# TODO make this configurable

# to build the docker machine
# docker build -t {{ToLower .Schema.Title}} -f {{.Settings.CMDPath}}dockerfiles/{{ToLower .Schema.Title}}/Dockerfile ./src/

# to run the built docker machine
# docker run -it {{ToLower .Schema.Title}}
`
