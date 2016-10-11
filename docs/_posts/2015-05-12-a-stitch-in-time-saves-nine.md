---
layout: post
title: Introducing VM Snapshots!
image: /assets/img/blog/snapshots.png
author:
  name: Nitin Gupta
  email: nitin@koding.com
excerpt_separator: "<!--more-->"
---

Getting your Koding Virtual Machine (VM) to a perfect state takes time, effort and patience. Over time, every little configuration change, preference and installation that you have labored over require preservation. Today, we announce the availability of one of the most requested features from our community..."OnDemand Snapshots". VM state preservation is a click away!
<!--more-->

**What are snapshots?**

A snapshot is a _point-in-time_ saved state of your VM. When you take a snapshot, Koding will place the contents of your _entire VM_ into a saved state. This includes all the installed software, configuration files, preferences, etc. When you take a snapshot, you are essentially freezing your Koding VM in time.

**How are snapshots beneficial?**

Snapshots are useful in several ways. Here are some common uses:

1. **Making a backup of your VM:** If you are about to embark on a major change to your VM, a timely snapshot can help you get back to a working state VM in case something goes wrong. This way, you can experiment as much as you need and be assured that you can always return to a state where you left things just the way you like them.
2. **The _perfect_ starting point:** A snapshot can be used **as a starting point** for a new VM. This means that you can set up a new VM as a clone of your existing VM thereby saving you hours in configuration time. This comes in very handy if you do a lot of client work or if you are a teacher and require a preserved state with your default software and preferences already in place.

A detailed guide on how to use snapshots is available [here][2].

Enjoy!


[1]: {{ site.url }}/assets/img/blog/snapshots.png
[2]: http://learn.koding.com/guides/vm-snapshot/
