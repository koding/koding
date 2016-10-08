---
layout: post
title: Update on the recent email notifications from Koding
author:
  name: Nitin Gupta
  email: nitin@koding.com
excerpt_separator: "<!--more-->"
---

Recently you may have received an email from us that may have caused you to be concerned about the security of your Koding account. Here is why you received this email and **why you should ignore it**.
<!--more-->

**What happened?**
Our current analysis has revealed that the problem arose when a backlog of emails related to system notifications (password changes, email address changes, etc.) were erroneously queued for delivery due to a change we pushed out to our production servers. Graph A below shows how many expected emails were to go out during the given time period and graph B shows how many were actually delivered. Clearly a stark difference. The increased number in graph B was due to the backlog being triggered. Needless to say, we have taken the necessary steps to avoid this in the future and we continue to monitor the situation.

**Graph A**

![QYTuFceyNE6o5Cl4IYscCzQ8Dt2u0eqCah4TmqVI3pE][1]

**Graph B**

![Attempted Emails][2]

**What's the impact?**
There is no security issue in regards to your account and your data is safe. We apologize for the inconvenience that this caused. Our engineering team is continuously monitoring the situation, however, if indeed you have an issue and you can't log into your account, please email us at [support@koding.com][3] and we'll have a look into it right away.

Have a wonderful and productive day and see you on Koding!

[1]: {{ site.url }}/assets/img/blog/qytufceyne6o5cl4iyscczq8dt2u0eqcah4tmqvi3pe.png
[2]: {{ site.url }}/assets/img/blog/kfosrqiem10jl3an1ztmdpsjqqexjtfbera1cehgwmy-1024x382.png
[3]: mailto:support@koding.com
