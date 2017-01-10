---
layout: doc
title: Using Docker
permalink: /docs/stack-for-docker
parent: /docs/home
---

# {{ page.title }}

If your team is working with Docker, it is easy to write a stack that will install Docker and Docker apps for your team.

### Full Stack

```yaml
provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'
resource:
  aws_instance:
    kuala-server:
      instance_type: t2.nano
      user_data: |-
        curl -fsSL https://get.docker.com/ | sh
        docker run docker/whalesay cowsay boo
```
On building the VM you will need to wait for a few minutes until Docker is installed and you should be able to see a whale saying 'boo'!

### ![boo][1]

Your developers can now run Docker images using the command `docker run `.Developers may be required to preface each docker command on this page with `sudo`. To avoid this behavior, you can create a Unix group called docker and add users to it.

* Example: `$ sudo docker run hello-world `

Developers can check what images are available through the terminal by typing `docker images` command. The command lists all the images on your local system. They should see `docker/whalesay` in the list.

```bash
$ docker images
REPOSITORY           TAG         IMAGE ID            CREATED            VIRTUAL SIZE
docker/whalesay      latest      fb434121fc77        3 hours ago        247 MB
hello-world          latest      91c95931e552        5 weeks ago        910 B
```

## Explanation:

### Installing Docker

Add the below line on your stack under `user_data` section to install Docker.

```bash
  curl -fsSL https://get.docker.com/ | sh
```

### Running Docker Apps

Docker allows you to run applications inside **containers** using a single command `docker run`, we will run **WhaleSay** image as an example. WhaleSay contains an adaption of the Linux cowsay game, it will display a whale saying whatever message you pass as parameter, in the below line the message is 'boo'! Of course in your case replace the WhaleSay image with the Docker app you want to install for your team.

```bash
docker run docker/whalesay cowsay boo
```

Reference: [Getting started with Docker][2]

[1]: {{ site.url }}/assets/img/guides/docker/docker-ready-boo.png
[2]: https://docs.docker.com/linux/step_one/
