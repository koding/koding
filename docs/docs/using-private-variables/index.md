---
layout: doc
title: Using Custom Variables
permalink: /docs/using-custom-variables
redirect_from: "/docs/using-private-variables"
parent: /docs/home
---

# {{ page.title }}

Using custom variables is useful in case you have some credentials that you do not wish to share with everyone. Variables in the custom variables section are used while the stack is building, but can not be seen by the users using your stack.

In this guide we will use the custom variables section to save the credentials required to access a particular FTP server and pull some files to users VM without sharing the credentials with users are listing them in the stack template.

### Add credentials to Custom Variables tab

We add our credentials in key value pairs format to the custom variables section

![Custom variables][1]

```yaml
  ftp_user: <your-ftp-user-name>
  ftp_pass: <your-ftp-password>
```

### Usage

To use the credentials, keys, or any important values you added to your Custom Variables tab, you use the below syntax. Remember that your Custom Variables are saved in **key-value pairs.** We use the **KEY** name preceded by **`${var.custom_`**

That means our variable will look like this: `${var.custom_**KEY-NAME**}`

In our example, to use our **`ftp_user`** and **`ftp_pass`** values we use:

* ${var.custom_**ftp_user**}
* ${var.custom_**ftp_pass**}

### Prepare the Stack Template

This stack will use the credentials defined in the Custom Variables section to access an FTP server and download a project file. The file will be extracted into the user home directory and privileges of the downloaded file and extracted folder will be changed to the user.

```yaml
provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'
resource:
  aws_instance:
    my-server:
      tags:
        Name: '${var.koding_user_username}-${var.koding_group_slug}'
      instance_type: t2.nano
      ami: ''
      user_data: |
        export USER_NAME=${var.koding_user_username}
        export USER_HOME=/home/${var.koding_user_username}

        apt-get update
        sudo apt-get install gzip gunzip

        wget ftp://${var.custom_ftp_user}:${var.custom_ftp_pass}@xx.xx.xx.xx/rocket-app.tar.gz -P $USER_HOME

        tar -zxvf $USER_HOME/rocket-app.tar.gz -C $USER_HOME
        chown $USER_NAME:$USER_NAME $USER_HOME/rocket-app.tar.gz
        chown $USER_NAME:$USER_NAME $USER_HOME/rocket-app
```

### Team Members View

Other developers would be able to build stack and view stack, but will not be able to view your custom variables

![Stack][2]

[1]: {{ site.url }}/assets/img/guides/custom-vars/custom-vars.png
[2]: {{ site.url }}/assets/img/guides/custom-vars/stack-viewer.png
