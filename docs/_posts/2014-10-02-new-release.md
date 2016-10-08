---
layout: post
title: Announcing the best Koding we have ever released!
author:
  name: Nitin Gupta
  email: nitin@koding.com
excerpt_separator: "<!--more-->"
---

We believe that every developer needs three essential things when it comes to learning or computing in the cloud:

1. A robust and flexible **development environment** a.k.a the VM
2. Amazing **development tools** to operate on this dev environment (IDE/Terminal)
3. A **developer community** of like minded peers with whom ideas can be exchanged

Koding has always had these key essentials but today, with the release of the next version of our platform, we're sending these essentials into _overdrive_.

<!--more-->

The first thing you will notice is the UI. Even though it's new, it retains a distinct visual connection to the previous style so you won't be shocked (or lost). The new UI should be self-explanatory, provide pixel pleasure and be fun to use. If you like it, send some [Tweet love our way][2]. Our designers and front-end team will be ever so thankful!

**Development Environment related enhancements**

1. **New Pricing!** We've heard you and we've made the changes. You can now have a paid Koding account for less than the cost of two beers per month. Check out the [all new pricing][3].
2. **Now hosted on Amazon EC2:** Besides running on Amazon's awesome (and reliable) infrastructure, your VM now comes directly from Amazon. It's not a sliced up host using LXC's (which tend to get unstable if the host becomes unstable).

![4J0LkDK][4]

3. **Public IPs:** Your VMs have public IPs! This is awesome for SSH access, custom development work, running services and a whole lot more. (Note: For our free users, the public IPs will rotate between restarts but will remain static for our paying users.)
4. **Custom domains and Nicknames:** Don't like the hostname we've given to your VM? Now you can easily add sub-domains or route your own domain to your VM...for free! You also have the ability to give nicknames your VMs so that they are easy to understand at first glance. Gone are the days of vm-0.xxx.xxx. Just call it "web server","database","API server", etc.
5. **Ubuntu 14.04:** Your VM will now be running the latest (and greatest) version of Ubuntu.![f3oiaLh][5]
6. **Updated VM Specs:** 1GB RAM, 3GB Storage and 1Core CPU...so much compute power!
7. **No more "click to continue!":** On old Koding, this feature prevented spam and abuse but also annoyed a lot of you. It's gone.
8. **VM Timeout increased to 60 minutes:** No more 15 minute timeouts….you can now take that video game break without the anxiety of having your VM shutting off automatically.

**Development Tools related enhancements**
Our IDE (which is built on top of Ace) and Terminal have also been overhauled. Much more to come but in the meanwhile, you can enjoy these features immediately:

1. Split pane views: Supports both horizontal and vertical splits. And you can merge them all back too.
2. Split IDE and Terminal: Both are on the same screen now, no more switching back and forth!
3. Shortcuts: Never take your hands off your keyboard again (at least while on Koding).
4. Workspaces: Most of you who wrote in with feature requests wanted this. Workspaces allow you to nicely collect all project related files into a folder and work on them as a collection. They also show up nicely under each VM for easy access.![4j9AeQM][6]
5. Drawing board: When you want to make a quick mind map of your ideas or just have some goofy fun!
6. New file search: Search anywhere and everywhere. Get to the file or keyword you want, fast!

**Development Community and Social feature enhancements**
Koding's developer community is a key draw for many of our users. With several enhancements and many all new functions, our community and social features are going to make you fall in love with Koding all over again.

1. Chat: Care to take things private or have a group discussion with your team/friends. Now you can do that with the comfort that no prying eyes are watching. Start a private chat with any Koding user or bring in your friends by inviting them using their email address.![ss-chat][7]
2. Channels: Follow your favorite channels or find new one's... all with the click of a button. Ruby, CSS, HTML, Go, Python, PHP, Javascript... whatever your interests may be, its now easy to participate and keep up to date.
3. Support for Markdown: Posts and comments, both now support markdown. You can respond to a request for code with a code fragment and it will be readable and gorgeous.

Many of you have been using Koding for a long time and your feedback has been essential as we finalized this release. **Thank you** for always steering us in the right direction.

Enjoy!

[1]: {{ site.url }}/assets/img/blog/ss-terminal.png
[2]: http://twitter.com/home?status=So%20much%20%23pixelPleasure%20over%20at%20the%20new%20%40koding.%20Sign%20up%20and%20get%20a%203GB%20VM%20for%20free!
[3]: https://koding.com/Pricing "Koding Pricing"
[4]: {{ site.url }}/assets/img/blog/4j0lkdk.png
[5]: {{ site.url }}/assets/img/blog/f3oialh.png
[6]: {{ site.url }}/assets/img/blog/4j9aeqm.png
[7]: {{ site.url }}/assets/img/blog/ss-chat.png
