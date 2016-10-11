---
layout: post
title: Koding response to Heartbleed - You're safe.
image: /assets/img/blog/heartbleed-safe-site-seal-2-262x300.png
author:
  name: Stefan Cosma
  email: stefan@koding.com
excerpt_separator: "<!--more-->"
---
<!--more-->

On April 7 a serious security vulnerability ([CVE-2014-0160][2]) was disclosed in the OpenSSL library. Like much of the internet, we responded to this critical issue by conducting a security review of our servers. The result of that review is as follows:

## Koding is unaffected by the security vulnerability known as Heartbleed.

**The primary reason for this is that we've never used the OpenSSL library** and so as a result, are unaffected. Koding built its own proxies using [Go][3] and Go has its own [implementation of TLS][4]. Therefore, you don't need to change your password (unless you used the same password on other sites that [have been affected][5] by Heartbleed).

We did a **thorough investigation** anyway and we've concluded that none of our servers were affected by this bug, nor was any user information compromised. However, that being said, our engineering team will **continue to monitor the situation** and share updates as they become available.

At Koding **we take security and transparency seriously**, which is why we want to let you know **your information is safe**. No additional step is required on your behalf. If you have any questions feel free to email us at [support@koding.com][6]

See you on [Koding][7]! :)

[1]: {{ site.url }}/assets/img/blog/heartbleed-safe-site-seal-2-262x300.png
[2]: https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-0160
[3]: http://golang.org/
[4]: http://golang.org/pkg/crypto/tls/
[5]: http://mashable.com/2014/04/09/heartbleed-bug-websites-affected/
[6]: mailto:support@koding.com?subject=I%20need help!
[7]: http://koding.com
