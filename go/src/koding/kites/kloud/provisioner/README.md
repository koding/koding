This JSON file is used to create an Amazon AMI based. Before creating an AMI be
sure the template is valid:

	$ packer validate koding-image.json

To create a new image execute, please fill the environment variables:

	$ AWS_ACCESS_KEY=""  AWS_SECRET_KEY="" packer build koding-image.json

If successfull you'll get a new image with the name "koding-latest
1459124123".  After you are sure it's stable go ahead and tag the AMI
from the AMI console to `koding-stable` so that Kloud can use it as base
when creating machines on the next iteration.

