---
layout: doc
title: Create an Azure stack
permalink: /docs/creating-an-azure-stack
parent: /docs/home
---

# {{ page.title }}

## Introduction

This guide will help you build a Microsoft Azure stack. [Microsoft Azure][1] is a collection of integrated cloud services, it offers [Compute service][2] to create virtual machines in Microsoft data centers.

You can configure the number of VMs and applications installed on each VM instance. Along with configuring VM size and region.
Your new team members will be able to use your stack to build their VMs environment and start working from day one.

> You will need to have a Microsoft Azure account to be able to create VMs. This will require you to provide your credit card information. You can sign up for a 30 day free trial and $200 in credit. Learn more about [Microsoft Azure pricing][3].

## Step by step guide

1. Click '+' sign to **Create a New Stack**

    ![Create new stack][4]

2. Choose **Azure** and click **Create Stack**

    ![Choose Azure][5]

3. Your default Azure stack is now created _(If you wish you can give your stack a name by clicking on **Edit Name** below your stack name)_.
In this modal you will find _four tabs_:

    1.  **Stack template**: This is your stack template
    2.  **Custom variables**: to define custom variables which you can use within your stack template, values there are hidden from the non-admin team members
    3.  **Readme**: This will be the text displayed in a message box when your team builds the stack
    4.  **Credentials**: add your Azure credentials here

    ![Stack template][6]

4. Edit your **Readme** file to greet your team and provide them with information regarding your project or stack

    ![Readme tab][7]

5. **Setting up your Azure Account**. You need to add your Azure account credentials to the credentials tab. To do that, login to your Azure account, and follow the below steps:



[1]: https://azure.microsoft.com
[2]: https://azure.microsoft.com/en-us/services/virtual-machines/
[3]: https://azure.microsoft.com/en-us/pricing/
[4]: {{ site.url }}/assets/img/guides/azure/create-new-stack.png
[5]: {{ site.url }}/assets/img/guides/azure/azure-provider.png
[6]: {{ site.url }}/assets/img/guides/azure/azure-default-stack.png
[7]: {{ site.url }}/assets/img/guides/azure/azure-readme.png
