module.exports = """
  {
    "provider": {
      "aws": {
        "access_key": "${var.access_key}",
        "secret_key": "${var.secret_key}"
      }
    },
    "resource": {
      "aws_instance": {
        "example": {
          "instance_type": "t2.micro",
          "ami": ""
        }
      }
    }
  }
"""