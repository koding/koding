#must set this in env var or tfvar
variable "marathon_url" {}

provider "marathon" {
  url = "${var.marathon_url}"
  # deployment_timeout = 5
}
