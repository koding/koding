---
layout: doc
title: Try on Koding button
permalink: /docs/koding-button
parent: /docs/home
---

# {{ page.title }}

### What is Koding and why use Try on Koding button?

![TryOnKoding.png][1]

Koding is a development environment as a service that helps you and your team hit the ground coding without the hassle of following tedious installation instructions, installing countless dependencies, and encountering annoying versioning errors. By writing or generating a YAML-based Stack Template, you configure your Stack. A Stack is your cloud based environment including VMs, databases, EIPs, and more. VMs can be any type and you can pick which packages, services, and software to install during initialization when your VMs are built. This way when a new developer comes on board, they can start working or testing your software immediately by directly building your stack.

The **Try on Koding** switch will allow you to embed the Try on Koding button on your website, where your developers and potential users can fire up your stack on the fly with a click of a button. This allows them to try your software within minutes without having to follow pages of instructions or, if they are a developer, start contributing code within minutes.

> ALERT: **Please note that enabling Try on Koding button makes your Team publicly accessible.**

### How to use it?

1. [Create your own Koding for Teams group][2]
2. Create a Stack template that will create the right Stack (VMs environment) for your software ([_example here_][3])
3. Click on **Stacks** -> **Koding Utilities**. Enable the **Try on Koding button**![EnableTryOnKoding.png][4]
4. Copy the code, and embed it into your website
  _![TryOnKodingCode.png][5]_

[1]: https://www.koding.com/hs-fs/hubfs/Koding-Guide_Teams/try-on-koding/TryOnKoding.png?t=1473370419565&width=180&height=54&name=TryOnKoding.png
[2]: https://koding.com/Teams/Create
[3]: /docs/two-vm-setup-apachephp-server-db-server
[4]: https://www.koding.com/hs-fs/hubfs/Koding-Guide_Teams/try-on-koding/EnableTryOnKoding.png?t=1473370419565&width=799&name=EnableTryOnKoding.png "EnableTryOnKoding.png"
[5]: https://www.koding.com/hs-fs/hubfs/Koding-Guide_Teams/try-on-koding/TryOnKodingCode.png?t=1473370419565&width=799&name=TryOnKodingCode.png
