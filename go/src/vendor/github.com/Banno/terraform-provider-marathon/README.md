# Marathon Terraform Provider

## Install
```
$ go get github.com/Banno/terraform-provider-marathon
```

## Usage

### Provider Configuration
Use a [tfvar file](https://www.terraform.io/intro/getting-started/variables.html) or set the ENV variable

```bash
$ export TF_VAR_marathon_url="http://marthon.domain.tld:8080"
```

```hcl
variable "marathon_url" {}

provider "marathon" {
  url = "${var.marathon_url}"
}
```

If Marathon endpoint requires basic auth (with TLS, hopefully), optionally include username and password:
```bash
$ export TF_VAR_marathon_url="https://marthon.domain.tld:8443"
$ export TF_VAR_marathon_user="username"
$ export TF_VAR_marathon_password="password"

```

```hcl
variable "marathon_url" {}
variable "marathon_user" {}
variable "marathon_password" {}

provider "marathon" {
  url = "${var.marathon_url}"
  basic_auth_user = "${var.marathon_user}"
  basic_auth_password = "${var.marathon_password}"
}
```

### Basic Usage
```hcl
resource "marathon_app" "hello-world" {
  app_id= "/hello-world"
  cmd = "echo 'hello'; sleep 10000"
  cpus = 0.01
  instances = 1
  mem = 16
  ports = [0]
}
```

### Docker Usage
```hcl
resource "marathon_app" "docker-hello-world" {
  app_id = "/docker-hello-world"
  container {
    docker {
      image = "hello-world"
    }
  }
  cpus = 0.01
  instances = 1
  mem = 16
  ports = [0]
}
```

### Full Example

[terraform file](test/example.tf)

## Development

### Build
```bash
$ go install
```

### Test
```bash
$ export MARATHON_URL="http://marthon.domain.tld:8080"
$ ./test.sh
```

### Updating dependencies

This project uses [godep](https://github.com/tools/godep) to manage dependencies. If you're using Golang 1.6+, to build, nothing needs done. Please refer to https://devcenter.heroku.com/articles/go-dependencies-via-godep for help with updating and restoring godeps.
