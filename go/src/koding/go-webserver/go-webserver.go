package main

import (
	"flag"
	"koding/db/models"
	"koding/tools/config"

	"github.com/koding/logging"
)

var (
	Name = "gowebserver"

	kodingTitle       = "Koding | Say goodbye to your localhost and code in the cloud."
	kodingDescription = "Koding is a cloud-based development environment complete with free VMs, IDE & sudo enabled terminal where you can learn Ruby, Go, Java, NodeJS, PHP, C, C++, Perl, Python, etc."
	kodingShareUrl    = "https://koding.com"
	kodingGpImage     = "koding.com/a/site.landing/images/share.g+.jpg"
	kodingFbImage     = "koding.com/a/site.landing/images/share.fb.jpg"
	kodingTwImage     = "koding.com/a/site.landing/images/share.tw.jpg"

	flagConfig = flag.String("c", "dev", "Configuration profile from file")
	Log        = logging.NewLogger(Name)

	kodingGroup *models.Group
	conf        *config.Config
)
