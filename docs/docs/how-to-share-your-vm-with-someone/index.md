---
layout: doc
title: How to share your VM with someone
permalink: /docs/how-to-share-your-vm-with-someone
parent: /docs/home
---

# {{ page.title }}

### What does "Shared VM" mean?

The "Share VM" feature allows you to give another Koding user full access to your VM even if you are not using your Koding.com account. The user will be logged in with your user on that VM. This is very different from Collaboration on Koding where you are working with someone in real-time and sharing the IDE and Terminal.

### What's the benefit?

There are several use cases where this makes sense. For example:

1. Multiple people are working on a project. They don't need to collaborate real-time but still need to access the same VM independently.
2. A "master" VM has been set up by the team lead that needs to be accessed by many team members (share code, docs, etc.).
3. Team member B needs to take over from team member A because a team is doing "follow the sun" development practice.
4. You are stuck somewhere, cannot be online but need someone else to look at your work. Can you think of more? If yes, [let us know][2]!

### How do I share my VM?

1. Head over to VM settings and locate the "Share VM" feature.
![1][3]
2. Turn on VM Sharing and add the username of a Koding user with whom you wish to share your VM with. ![2][4]
3. The user with whom the VM has been shared will now see an accept/reject notice. ![3][5]
4. Once they accept, the shared VM will appear in the sidebar as a new available resource. ![4][6]

### How can I stop sharing my VM?

- Go into VM settings and remove the user with whom you no longer wish to share your VM, or turn off sharing completely. ![5][7]

### How do I leave a shared VM?

- Click the VM settings for the shared VM and then select "Leave Shared VM" to remove the VM from your Sidebar.![6][8]

[1]: https://github.com/koding/kdlearn/blob/master/guides/collaboration
[2]: mailto:support@koding.com
[3]: {{ site.url }}/assets/img/guides/share-vm/vm-sharing-off.png
[4]: {{ site.url }}/assets/img/guides/share-vm/share-vm-on-choose-teammate.png
[5]: {{ site.url }}/assets/img/guides/share-vm/john-share-request2.png
[6]: {{ site.url }}/assets/img/guides/share-vm/john-has-access2.png
[7]: {{ site.url }}/assets/img/guides/share-vm/stop-sharing-vm.png
[8]: {{ site.url }}/assets/img/guides/share-vm/leave-shared-vm.png
