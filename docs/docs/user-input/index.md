---
layout: doc
title: User Input
permalink: /docs/user-input
parent: /docs/home
---

# {{ page.title }}

You can ask the user to add inputs through the GUI before a stack is built and use their values in your stack.

By simply referring to a variable, Koding will automatically understand that you need a user input and will prompt your developers for input. Your variable needs to be preceded by **`${var.userInput_`**

example: ${var.userInput_**variable**}

So if you want to ask a developer for their github username, you can use  **`${var.userInput_github_username}`**. This will prompt your developers for input with a field labeled as your variable name "**github_username**"

### Stack Example
```yaml
koding:
  userInput:
    user_name: text
    user_pass: password
    key: textarea

provider:
  aws:
    access_key: '${var.aws_access_key}'
    secret_key: '${var.aws_secret_key}'
resource:
  aws_instance:
    example:
      instance_type: t2.nano
      user_data: |-
        echo "${var.userInput_user_name}"
        echo "${var.userInput_user_pass}"
        echo "${var.userInput_key}"
```

In the above example we are asking our developers to enter three values **user_name**, **user_pass**, & **key**. These are defined under the **user_data** section in our example, but you can use user input variables in any area in your stack template. Once a developer builds this stack, they will be prompted with a GUI box asking to enter the values for the above three variables as seen below.

![User-input-modal-1.png][1]

> You can define each variable's field type (_text, textarea, password_...etc) as we did in the beginning of our stack. You will notice that the input boxes size and behavior changes according to the field

![user-input-gif.gif][2]

In our example when the stack is built, we are only displaying the values the user entered. However you can see a more practical example in our [GitHub guide][3].

Congratulations, you can now make use of user inputs in your Stack template.

[1]: {{ site.url }}/assets/img/guides/user-input/inputvars.png
[2]: {{ site.url }}/assets/img/guides/user-input/userinput-walkthrough.gif
[3]: /docs/using-github-in-stacks
