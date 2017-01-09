---
layout: doc
title: Setup AWS IAM user
permalink: /docs/setup-aws-iam-user
parent: /docs/home
---

# {{ page.title }}

It is a good security (and recommended) practice to create a user on AWS other than your root account. And use the new account key pairs in your AWS and Koding accounts and Stacks. To learn more about AWS account best practices [read more here][1].

> As Koding for Teams creates & manages your AWS resources, it will use EC2, S3 and EBS services from your AWS account. Of course exact services used depends on your Stack script.

There are two required policies that need to be enabled for the new IAM user to be able to create & build Stacks using EC2s.

* **AmazonEC2FullAccess**
* **IAMReadOnlyAccess**

![IAM_policies.png][2]

The steps are:

1. Create a [new user][3] (make sure to generate the Access Keys and save them)
2. Create a [new group][4] and add the user to this group
3. Assign the above two policies (see screenshot) to the created group

Now you can use the new user Access and Secret Keys with your Koding account in the AWS credentials tab to build your stacks.

### Step by step guide

1. Log in to your AWS account, choose **Services**, then choose **[IAM][5]** (Identity and Access Management)
2. Create a **new user**
    1. Choose a user name, we created a user called "koding-user". We also made sure that **Generate an access key for each user is enabled**

        ![user01-3.png][6]

    2. Click **Show User Security Credentials**

        ![user02-1.png][7]

    3. Save the user's keys (you can also **download** them) and click **close**

        ![user03.png][8]

    4. User **koding-user** created successfully

        ![user04-1.png][9]

3. Create a **new group** and follow the online wizard
    1. Choose a group name, we choose the name "Developers"

        ![group01.png][10]

    2. Choose the access policies
        * **AmazonEC2FullAccess**
        * **IAMReadOnlyAccess**

        ![group02.png][11]

    3. Review and click **create**

        ![group03.png][12]

4. Add the user to the group
    1. Go to the **Users** tab, select and check the user you created and click **User Actions** -> **Add Users to Group**

        ![user-add01.png][13]

    2. Select the **koding-user** we just created

        ![user-add02.png][14]

    3. User was added to group successfully

        ![user-add03.png][15]

Congratulations! You have now created a user on AWS with the required access permissions to build stacks without sacrificing your root user account.

> If you want to use Route53 or special settings in AWS, you must extend the **Permissions** capabilities of the group you just created. Otherwise you and your team will receive an error while building the stack that the user does not have enough permission to carry out those actions. For example, if you are creating an AMI user to use with a Route53 stack setup (_check our [Route53][16] guide!_) you would need to add the below permissions to the AWS IAM user/group
>
> * AmazonRoute53FullAccess
> * AmazonRoute53DomainsFullAccess

[1]: http://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html#create-iam-users
[2]: {{ site.url }}/assets/img/guides/stack-aws/5-iam/IAM_policies.png
[3]: http://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html
[4]: http://docs.aws.amazon.com/IAM/latest/UserGuide/id_groups.html
[5]: https://console.aws.amazon.com/iam/home
[6]: {{ site.url }}/assets/img/guides/stack-aws/5-iam/images2/user01-3.png
[7]: {{ site.url }}/assets/img/guides/stack-aws/5-iam/images2/user02-1.png
[8]: {{ site.url }}/assets/img/guides/stack-aws/5-iam/images2/user03.png
[9]: {{ site.url }}/assets/img/guides/stack-aws/5-iam/images2/user04-1.png
[10]: {{ site.url }}/assets/img/guides/stack-aws/5-iam/images2/group01.png
[11]: {{ site.url }}/assets/img/guides/stack-aws/5-iam/images2/group02.png
[12]: {{ site.url }}/assets/img/guides/stack-aws/5-iam/images2/group03.png
[13]: {{ site.url }}/assets/img/guides/stack-aws/5-iam/images2/user-add01.png
[14]: {{ site.url }}/assets/img/guides/stack-aws/5-iam/images2/user-add02.png
[15]: {{ site.url }}/assets/img/guides/stack-aws/5-iam/images2/user-add03.png
[16]: /docs/assigning-domain-names-with-route53
