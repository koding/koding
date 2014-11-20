maintainer        "Matthew Baird"
maintainer_email  "mattbaird@gmail.com"
license           "Apache 2.0"
description       "Installs go language from duh's Ubuntu PPA"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.0.0"
recipe            "golang", "Installs go"

depends "apt"
supports "ubuntu"
