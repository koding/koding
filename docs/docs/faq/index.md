---
layout: doc
title: FAQ
permalink: /docs/faq
redirect_from: "/docs/common-questions"
parent: /docs/home
---

# {{ page.title }}

1. [How do I create a new Koding Team?](#new-koding-team)
2. [What is a stack file?](#user-content-createstack)
3. [How do I invite new team members?](#invite-team-members)
4. [How do I setup a stack for my team?](#setup-stack-for-team)
5. [I receive an error related to the parameter `availabilityZone` when creating my stack file!](#user-content-availabilityZone)
6. [Me or one of my teammates is receiving an error `InstanceLimitExceeded` when building a stack](#user-content-InstanceLimitExceeded)
7. [How can I delete a stack?](#delete-stack)
8. [How can I delete a stack template file?](#delete-stack-template)

* * *


### <a name="new-koding-team"></a> How do I create a new Koding Team?

* Creating a team in koding is easy and straight forward, just go to [www.koding.com][10], click **Sign Up** for a new account and follow the on screen steps.

---

### <a name="user-content-createstack"></a> What is a stack file?

* Koding for Teams allows you to create a development **Stack** for your team. A stack file is a YAML file that describes the complete environment configuration which may include multiple VMs with different packages and applications installed on each VM. During the **Stack** setup, you can also configure a code pull from any of the famous code repository providers.

---

### <a name="invite-team-members"></a> How do I invite new team members?

* Go to Team settings
* Click Invitations from left pane
* Type in user(s) email, and optionally their first and last names. Check "Admin" if they will be admin users
* Click **Invite Members**

---

### <a name="setup-stack-for-team"></a> How do I setup a stack for my team?

* Click **Stacks** from the left side bar
* Click **Group Stack Templates**
* Click **Create New Stack**

Please check the Stack setup guide at [Create a stack][11]

---

### <a name="user-content-availabilityZone"></a> I receive an error related to the parameter `availabilityZone` when creating my stack file,_ex_:

> Error applying plan: 1 error(s) occurred: *aws_subnet.main_koding_subnet: Error creating subnet: InvalidParameterValue: Value (us-east-1b) for parameter availabilityZone is invalid. Subnets can currently only be created in the following availability zones: us-east-1d, us-east-1a, us-east-1c, us-east-1e.

* This is related to your AWS account, you may try to change the **Region** in your credentials tab within the stack setup phase:
 ![region-1.png][1]

---

### <a name="user-content-InstanceLimitExceeded"></a> Me or one of my teammates is receiving an error `InstanceLimitExceeded` when building a stack:

> aws_instance.apache_server: Error launching source instance: **InstanceLimitExceeded:** Your quota allows for 0 more running instance(s). You requested at least 1 status code: 400, request id:

* Check the number of VMs in your AWS account, the error indicates that you exceeded your maximum allowed VMs. Follow the [AWS Terminate Your Instance user guide][2] to shutdown some of the unused VMs. _Make sure you select the correct region in your AWS account dashboard_.

---

### <a name="delete-stack"></a> How can I delete a Stack?

1. To delete the stack and the entire VMs created in this Stack, click on the Stack name from the left side panel and click **Destroy VMs.**

    > All your data on these VMs will be completely lost.

    ![destroy-vms.png][3]

2. Click on **Stacks** from left side panel, click the **Remove From Side Bar** on the stack you want to remove

    ![remove-from-side-bar.png][4]

    > **ALERT:** If you have only one stack you will not be able to delete it. You need to have at least two to be able to delete one of them.

---

### <a name="delete-stack-template"></a> How can I delete a stack template file?

* Click on **STACK** from the left side bar to open the stack catalog, click **Stacks**, open the stack you want to delete (click on its name) and click **Delete Stack Template**.
![delete-stack.png][5]

[1]: {{ site.url }}/assets/img/guides/FAQ/region-1.png
[2]: http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/terminating-instances.html#terminating-instances-console
[3]: {{ site.url }}/assets/img/guides/FAQ/destroy-vms.png
[4]: {{ site.url }}/assets/img/guides/FAQ/remove-from-side-bar.png
[5]: {{ site.url }}/assets/img/guides/FAQ/delete-stack.png
[10]: {{ site.url }}
[11]: {{ site.url}}/docs/creating-an-aws-stack
