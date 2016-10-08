---
layout: post
title: Introducing the Koding Package Manager (kpm)
image: /assets/img/blog/screenshot-from-2014-11-25-222438.png
author:
  name: Stefan Cosma
  email: stefan@koding.com
excerpt_separator: "<!--more-->"
---
<!--more-->
_pronounced: 'kay-pm'_

Before we launched [the new and improved Koding][1], one of the most beloved features was the Koding App Catalog. Koding Apps allowed you to install the most popular frameworks (like Wordpress, Joomla, MySQL, etc.) with just the click of a button. It was easy and it meant you could be up and running with a new software package or a framework in minutes vs spending hours on configurations.

The architecture of new Koding disallowed us to bring Koding Apps to you in their native form and it devastated quite a few of you. Today, we are super excited to introduce you to KPM, Koding's new installer that will serve the same purpose as our Apps framework did.

The Koding Package Manager is the easiest way to get started on your project without having to go through all the installation and configuration hassle. Just one command that does everything for you!

```shell
$ kpm help
usage:
  kpm install <name>
  kpm list
  kpm -h | --help
  kpm --version
```

To get started with the Koding Package Manager just head over to [this guide][3] and follow the steps required to install and configure KPM and then just install your favorite framework or program from the list of available installers.

KPM is fully extensible so if you want to contribute, you can [fork the project on Github][4] and add your own installers for the Koding community!

[1]: http://blog.koding.com/2014/10/new-release/ "Announcing the best Koding we have ever released!"
[2]: {{ site.url }}/assets/img/blog/screenshot-from-2014-11-25-222438.png
[3]: http://learn.koding.com/guides/getting-started-kpm/ "Koding Package Manager Guide"
[4]: https://github.com/koding/kpm-scripts "KPM on Github"
