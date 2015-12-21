## Update AMI of Koding VM's.

First of all, to update the AMI we need two tools. One ise packer
https://packer.io/ and images (I've wrote it myself to automize AMI handling)
https://github.com/fatih/images. Go ahead and install them (just download and
put them to /usr/loca/bin). 

Create a `.imagesrc` file (a configuration file for `images`). Here is mines
(please add ACCESS and SECRET Key for the account AWS Koding-vms):

```
providers = ["aws"]

[aws]
access_key = "FILL_HERE"
secret_key = "FILL_HERE"
regions    = ["all"]
```

Once you have this. Calling `images list` returns something like:

```
AWS Region: eu-west-1 (2 images):
    Name				ID		State		Tags
[1] koding-base-latest-1443775399	ami-e9d9ec9e	available	[Name:koding-stable-old]
[2] koding-base-latest-1446024878	ami-3d8f504e	available	[Name:koding-stable]

AWS Region: ap-southeast-1 (2 images):
    Name				ID		State		Tags
[1] koding-base-latest-1443775399	ami-900d1bc2	available	[Name:koding-stable-old]
[2] koding-base-latest-1446024878	ami-bf8a4ddc	available	[Name:koding-stable]

AWS Region: us-east-1 (2 images):
    Name				ID		State		Tags
[1] koding-base-latest-1443775399	ami-ab0746ce	available	[Name:koding-stable-old]
[2] koding-base-latest-1446024878	ami-5387f639	available	[Name:koding-stable]

AWS Region: us-west-2 (2 images):
    Name				ID		State		Tags
[1] koding-base-latest-1443775399	ami-50a54063	available	[Name:koding-stable-old]
[2] koding-base-latest-1446024878	ami-cfabbeae	available	[Name:koding-stable]
```

Now to create an AMI do the followings (same keys as in imagesrc). Be sure you
are in the root directory of our Koding Git Repo:

```
cd go/src/koding/kites/kloud/provisioner
AWS_ACCESS_KEY="" AWS_SECRET_KEY="" packer build template.json
```

This is going to create an AMI and copy it to all regions automatically. The
new AMI will have the tag "koding-test". Packer will do this for you, so it's
all automated. once that is finished, call again `images list` and you'll see
the following:

```
AWS Region: eu-west-1 (2 images):
    Name				ID		State		Tags
[1] koding-base-latest-1441104079	ami-25082c52	available	[Name:koding-stable-old]
[2] koding-base-latest-1443775399	ami-e9d9ec9e	available	[Name:koding-stable]
[3] koding-base-latest-1446024878	ami-3d8f504e	available	[Name:koding-test]

AWS Region: ap-southeast-1 (2 images):
    Name				ID		State		Tags
[1] koding-base-latest-1441103079	ami-855241b5	available	[Name:koding-stable-old]
[2] koding-base-latest-1443775399	ami-900d1bc2	available	[Name:koding-stable]
[3] koding-base-latest-1446024878	ami-bf8a4ddc	available	[Name:koding-test]

AWS Region: us-east-1 (2 images):
    Name				ID		State		Tags
[1] koding-base-latest-1441103079	ami-89e365e2	available	[Name:koding-stable-old]
[2] koding-base-latest-1443775399	ami-ab0746ce	available	[Name:koding-stable]
[3] koding-base-latest-1446024878	ami-5387f639	available	[Name:koding-test]

AWS Region: us-west-2 (2 images):
    Name				ID		State		Tags
[1] koding-base-latest-1441103079	ami-44707b16	available	[Name:koding-stable-old]
[2] koding-base-latest-1443775399	ami-50a54063	available	[Name:koding-stable]
[3] koding-base-latest-1446024878	ami-cfabbeae	available	[Name:koding-test]
```

So now our AMI's are finished and ready to use. However it's not pushed to
production. So how do push it?

We basically change the tags from `koding-test` to `koding-stable`. Kloud is
automatically fetching the AMI that is tagged with "koding-stable". Because
chaning the tags on all regions is cumbersome, we are going to use the "images"
tool. For that we need to three things:

1. Rename tags from koding-test to koding-stable
2. Rename current tags of koding-stable to koding-stable-old
3. Delete previously koding-stable-old tagged AMI's

With images the commands for the picture above would be:

1. `images modify --create-tags "Name=koding-stable" --ids ami-3d8f504e,ami-cfabbeae,ami-5387f639,ami-bf8a4ddc`
2. `images modify --create-tags "Name=koding-stable-old" --ids ami-e9d9ec9e,ami-50a54063,ami-ab0746ce,ami-900d1bc2`
3. `images delete -ids ami-25082c52,ami-89e365e2,ami-855241b5,ami-44707b16`


So thats it. Once all is finished, "images list" should show you the following:

```
AWS Region: eu-west-1 (2 images):
    Name				ID		State		Tags
[1] koding-base-latest-1443775399	ami-e9d9ec9e	available	[Name:koding-stable-old]
[2] koding-base-latest-1446024878	ami-3d8f504e	available	[Name:koding-stable]

AWS Region: ap-southeast-1 (2 images):
    Name				ID		State		Tags
[1] koding-base-latest-1443775399	ami-900d1bc2	available	[Name:koding-stable-old]
[2] koding-base-latest-1446024878	ami-bf8a4ddc	available	[Name:koding-stable]

AWS Region: us-east-1 (2 images):
    Name				ID		State		Tags
[1] koding-base-latest-1443775399	ami-ab0746ce	available	[Name:koding-stable-old]
[2] koding-base-latest-1446024878	ami-5387f639	available	[Name:koding-stable]

AWS Region: us-west-2 (2 images):
    Name				ID		State		Tags
[1] koding-base-latest-1443775399	ami-50a54063	available	[Name:koding-stable-old]
[2] koding-base-latest-1446024878	ami-cfabbeae	available	[Name:koding-stable]
```

### Updating Softlayer base image

Install packer-builder-softlayer plugin from our fork [koding/packer-builder-softlayer](https://github.com/koding/packer-builder-softlayer):

```
$ # assuming ~ is your $GOPATH
$ git clone git@github.com:koding/packer-builder-softlayer ~/src/github.com/leonidlm/packer-builder-softlayer
$ # assuming $GOPATH/bin is in your $PATH where packer executable is located
$ go install github.com/leonidlm/packer-builder-softlayer
```

Locate the kloud `ssh\_key\_id` to use during build with `sl` command:

```
$ go install koding/kites/kloud/scripts/sl
$ sl sshkey list -label kloud -user root
ID		Label	Fingerprint		Created						Users
12345	kloud	12:34:56:67:89	2016-02-05T17:55:00+02:00	[root]
```

Navigate to koding repo and build the image:

```
koding $ cd go/src/kites/kloud/provisioner
koding $ export SOFTLAYER\_USER\_NAME=<?>
koding $ export SOFTLAYER\_API\_KEY=<?>
koding $ export SOFTLAYER\_PRIVATE\_KEY="<?>/credentials/private_keys/kloud/kloud_rsa.pem"
koding $ export SOFTLAYER\_SSH\_KEY\_ID=12345
koding $ packer build -only=softlayer template.json
...
Build 'softlayer' finished.

==> Builds finished. The artifacts of successful builds are:
--> softlayer: dal05::dfd85d27-af0b-4ca1-a1d7-b67db3011aee (koding-base-latest-1450290568)
```

Tag the new image as `koding-stable` and untag the old one:

```
koding $ images modify -create-tags Name=koding-stable -ids NEW_ID
koding $ images modify -delete-tags Name -ids OLD_ID
```
