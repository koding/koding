---
layout: post
title: Goodbye Koding Solo, Welcome Koding for Teams!
image: /assets/img/blog/koding-for-teams.png
author:
  name: Devrim Yasar
  email: devrim@koding.com
redirect_from: "/blog/goodbye-koding-solo-welcome-koding-for-teams"
excerpt_separator: "<!--more-->"
---

We are stoked to announce that today Koding for teams will just be Koding. We couldn't be more excited about the new platform; it has the best of Koding that you already know, and  includes amazing new team-centric improvements that you've been asking for.

<!--more-->

Beginning today, Koding will be one product; that is **Koding For Teams, which we will call “Koding”**. It is now a development environment as a service that helps you and your team hit the ground coding without the hassle of setting up your dev. environments.

You ask, but why? Let’s get to it.

## We listened to our users

### Our users wanted Teams, because they collaborate with people they already know.

Since the first day we started Koding, we envisioned a platform where learners, students, tinkerers, and hobbyists could team up with senior developers to form communities of productivity. Last year, Koding hosted more than 200,000 collaboration sessions, and the number of participants totalled around half a million. When we looked at the data, we learned that more than 90% of those collaborators knew each other in advance. We see users sign up, directly join a collaboration session, and have subsequent sessions with the same group of people all the time. This meant to us that we needed to support this type of use-case in a big way. In fact when we asked our users, this is what we found:

![What started Koding for Teams]({{ site.url }}/assets/img/blog/Screen_Shot_2016-03-01_at_8.12.01_AM.png "What started Koding for Teams")

And so we built our Teams product.

### Active users have their own VMs

In 2015 we released KD, a way to [connect your own VMs to Koding](http://www.koding.com/docs/connect-your-machine); it was a huge success. More than half of our weekly active users connected their VMs from Digital Ocean, AWS, and Azure, back to Koding. This meant that our active users didn’t need a free VM service, and that being able to access their own VMs as easily as logging in to Koding, was more important. We launched KD to enable this connection for free and logged over 1.5 VMs connected per user on average. For the new Koding, we rebuilt the entire architecture of the platform so that you are able to bring your own cloud credentials and provision your own stack using any size VMs (previously limited to only the t2.micro).

## Remove Confusion, and have a clear message

### 1- Koding is ~~an Online IDE~~ Dev. Environment Automation platform.

We never wanted to be called an Online IDE. We have always wanted developers to use their own IDEs, and now, they can do just that. We never thought a single IDE would unite all developers anyway, and being browser-only can be a huge pain point. A web IDE is great for collaboration but as a developer, you want Sublime, Eclipse, IntelliJ etc. Their feature-set cannot be rewritten into one tool.

We saw in our usage data that, outside of collaboration, developers return to their desktop IDEs, and we needed to support that use-case. With KD (our binary) you can mount every server that you access on Koding; for the first time you can have them locally available. (btw It’s amazing - it’s not ssh or ftp, [read more here) Create VMs in the cloud, or on your localhost using Vagrant & Virtualbox, and use Koding with your local IDEs.](http://www.koding.com/docs/connect-your-machine)

![Koding uses data from user requests to make its new product.]({{ site.url }}/assets/img/blog/Screen_Shot_2016-03-01_at_8.12.27_AM.png "Koding uses data from user requests to make its new product.")

_What I like most about this graph is that 10% of our collaboration sessions were with more than 50 people._

### 2- Koding ~~teaches~~ allows you to code.

Koding is not a teaching platform like Coursera or Udacity. By providing easy access to VMs, and by promising things like: “Development on Koding is easy” and “You don’t need to install anything” we inadvertently opened the floodgates for people who had never seen a terminal in their lives. When that happened, we tried to help them as much as we could, but this was a major distraction to us. They confused Koding for a code teaching platform, but it was only meant to be easy access to a well configured computer. We created Koding Package Manager [(KPM) and countless docs to make it easier for them - how to install wordpress, drupal, angular, or react - but in reality, Koding is meant for developers and not meant for absolute beginners.](https://www.koding.com/docs/getting-started-kpm)

### 3- Koding is not Slack, _but we totally integrate!_

When we started, most people used Skype or Hangouts and we didn’t have many integration opportunities. So we made our own communication platform within Koding. Fast forward to 2016, Slack replaced most of the communication tools and became the one. We use Slack at Koding. They have amazing integration capabilities so we decided that we integrate with others and focus on doing what we do best: development environment automation. **Just like we let you choose your cloud provider, now we let you choose your communication provider.**

### 4- Koding is not a Free Hosting Service

Oh boy, this was the worst part. Behind the scenes a large percentage of Koding’s  engineering resources was spent detecting fraudulent activity, like bitcoin mining, minecraft servers, DDOS attacks on other people’s servers, password sniffing, and sometimes downright illegal activities (phishing and credit card fraud). These people were using stolen identities to automate registrations for free VMs. Like that’s not enough, we had two people on the team constantly monitoring the activity feed to make sure everything was ok. This is why we do not provide free VMs anymore. Just bring your cloud credentials, ([AWS offers 12 months free!](https://aws.amazon.com/free/))

![Koding used to receive hundreds of AWS reports]({{ site.url }}/assets/img/blog/Screen_Shot_2016-03-01_at_8.12.51_AM.png "Koding used to receive hundreds of AWS reports")

_Receiving hundreds of these everyday is not the funnest part of our lives._

### Introducing new Koding, it’s amazing and free for teams up to 4 people!

![Koding For Teams]({{ site.url }}/assets/img/blog/koding-for-teams.png "Koding For Teams")

It’s exactly like we say: “Flawlessly configured dev environments in one click.” You write the stack script, and your entire dev environment is configured for your team and everyone that joins your team. Share your cloud credentials with the team, or use your own localhost. We enjoy using it and hope you will too. We are no longer offering single developer accounts, registration for our solo product has closed. If you have an account and you’re actively using it, meaning you log in at least once per week, you can keep your VM and work on it as usual. If you paid for an account, you will experience no changes. Koding is free for teams up to 4 people, so go sign up and have fun. We mean it, seeing all those servers auto-provision in real time is a lot of fun!

:> Code on!

Devrim & Team Koding
