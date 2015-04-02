This JSON file is used to create an Amazon AMI based. Before creating an AMI be
sure the template is valid:

	$ packer validate template.json

To create a new image execute, please fill the environment variables:

	$ AWS_ACCESS_KEY=""  AWS_SECRET_KEY="" packer build template.json

If successfull you'll get a new image with the name "koding-latest 1459124123".
Packer will try to Copy the image to other regions so this might take a couple
of minutes. After you are sure it's stable go ahead and tag the AMI from the
AMI console to `koding-stable` so that Kloud can use it as base when creating
machines on the next iteration. By default the tag is `koding-test`. 


### Create a Base Image to be used in Packer instead of default

* Why:

Create a Image that is 3GB instead of 8GB. 

* Requirements:

Middleman instance: An EC2 instance (t2.small) with an ssh key deployed
Source instance: An EC2 instance which AMI we are going to use. Can be a t2.micro

All steps should be in the same zone, such as us-east-1d

* Go to "Volumes" section, create an empty 3GB Volume and name it as "Target".
  It should not based on any snapshot, left it out as empty. State should be
  "Available". We are going to use it soon.
* Stop the "Source" instance that we created before. Go to "Volumes" section
  and find the volume that is attached to this instance. The state should be
  "in-use". Deattach it and name it as "Source".

Now you have two volumes, each de attached, with the names of "Target" and
"Source". Attach them to the middleman instance. First attach "Target". The
device name is automatically assigend, such as "/dev/sdf".  Attach now the
"Source" volume. The device name is automatically assigend, such as "/dev/sdg".


* SSH into the Middleman instance
* Be root
* Run `fdisk -l` to see all attached disks.

Target doesn't have any partition and will be in form of /dev/xvdf
Source has a partition and will be in form of /dev/xvdg and /dev/xvdg1 (boot partiiton)

Just be sure you see them. If not please double check the previous steps.

* Resize the source disk (note that the partition! Be sure you write without the number):

	resize2fs -M -p /dev/xvdg 

You'll see an output like `Resizing the filesystem on /dev/xvdh1 to 239534 (4k)
blocks`. Here the `239534` is the number of blocks. Calculate the count via:

	count = blocks * 4 / (16 * 1024)

For example, count should be for the number above: (239534*4) / (16*1024) =>
58.479980469, round it to an upper integer means count is for us `60`


* Now copy the whole disk to our `Target` volume via:

	dd if=/dev/xvdh of=/dev/xvdf bs=16M count=COUNTNUMBER

Here COUNTNUMBER is the number obtained via the formula above. In the example
it was `60`.

* If finished, run a `fdisk -l`. You should see that the target volume has now
  a partititon called `/dev/xvdf1`. However we don't have an access to it yet.
  Just go to the "Volumes" section, deattach and reattach it again to the
  middleman instance.

* Do a `fdisk -l` again to see our instance

* Maximize the previously resized disk (do it on the partition!):

  resize2fs -p /dev/xvdf1

* Check that everything is ok

  e2fsck -f /dev/xvdf1

Now everything is done! (mostly) 

* Deattach our Target souce and attach it to Source instance we've created in
  the beginning. Remember it was a 8GB instance. Be sure you attach the Target
  source as `/dev/sda1`. Because it has no volumes, this will be the main boot 
  partition

* Run the source instance and check if you see the log's via `Get system log`
  menu. If you see them that means our 3GB Volume is ready for images.

* Stop the source instance

* Create a snapshot from the Targe volume. Just go to "Volumes" section and
  create a snapshot from the Target volume (because we labeled it as "Target"
  it's easy to find it ;))

* Go to "Snapshots" section and create an Image from the snapshot. Rename it
  properly please.

* Go to AMI section and find the AMI ID. This will be our Base AMI to be used
  within Packer :)



