---
layout: doc
title: Koding Stacks Variables
permalink: /docs/koding-stacks-variables
parent: /docs/home
---

# {{ page.title }}

There are a few built-in Koding variables that you can use in your stacks. You may have noticed already in previous stacks that we used `${var.koding_user_username}` and `${var.koding_group_slug}` under `tags:` section

```yaml
  tags:
    Name: '${var.koding_user_username}-${var.koding_group_slug}'
```

There are more variable that you can use in your stacks:

```yaml
${var.koding_user_email}                  #logged in user email
${var.koding_user_username}               #logged in user username
${var.koding_account_profile_firstName}   #logged in user first name
${var.koding_account_profile_lastName}    #logged in user last name
${var.koding_group_title}                 #Team title
${var.koding_group_slug}                  #Team slug (first part of the team url)
```

Trying this on Koding for Teams:

```yaml
provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'
resource:
  aws_instance:
    webserver:
      instance_type: t2.nano
      tags:
        Name: '${var.koding_user_username}-${var.koding_group_slug}'
      user_data: |-
        echo "user email ${var.koding_user_email}"
        echo "user name ${var.koding_user_username}"    
        echo "first name ${var.koding_account_profile_firstName}"  
        echo "last name ${var.koding_account_profile_lastName}"   
        echo "group title ${var.koding_group_title}"  
        echo "group slug ${var.koding_group_slug}"
```

Once we build our VM we can check the build logs to see the output of our commands

> If you don't see the build logs opened by default, click on VM settings from the side panel and click on "Show Build Logs"

![Koding vars][1]

[1]: {{ site.url}}/assets/img/guides/koding-vars/echooutput.png
