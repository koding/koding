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

> You will need to have a Microsoft Azure account to be able to create VMs. See [Microsoft Azure pricing][3].

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

5. **Setting up your Azure Account**. You need to add your Azure **Publish Settings** file content and **Subscription ID** to the credentials tab. To do that, login to your Azure account, and follow the below steps:

    1. First, get your **Publish Settings** file by following the [steps in this URL][8]. Or open this link directly [https://manage.windowsazure.com/publishsettings][9]:

        > If you haven't created an account yet, please visit [Azure website][1] to create one now.

        ![Azure steps to get publish settings file][10]

    2. Your **Publish Settings** will be downloaded to your computer, make sure you know its location as you will need to copy its contents later

        ![Azure download publish settings file][11]

    3. To get your **Subscription ID** go to your Account Billing information, then:

        - Click **ACCOUNT** -> **Subscriptions** and click on your subscription plan

        ![Azure get your subscription ID][12]

        > Please note that you need to be at least on the Pay-as-you-go or developer trial. The Free trial has some limitations and may not allow your stack to build successfully. [See subscription offers](https://account.windowsazure.com/signup?showCatalog=True)

        - Scroll down to your **Subscription ID**

        ![Azure copy your subscription ID][13]

    4. Now that you have your credentials information ready, go to the credentials tab on Koding for Teams, copy the contents of your downloaded **Publish Settings** file and paste it in your Koding credentials tab. Also paste your **Subscription ID**


        1. **Title**: Give your credentials a name
        2. **Publish Settings**: copy & paste the contents of the downloaded **Publish Settings** file here
        3. **Subscription ID**: your subscription ID on Azure that you fetched earlier
        4. **Location**: choose the region you want to create your VM in
        5. **Storage**: replication option for your Azure data [learn more here](https://docs.microsoft.com/en-us/azure/storage/storage-redundancy)

        ![Azure credentials][14]

        Once you are done click **Save this & continue** to verify your credentials

    7. Once your credentials are saved & verified you will be directed back to your Stack template. Click **Save** on the top right

        ![Azure Save Stack][15]

    8. Click **Initialize** to start your stack

        ![Azure Init Stack][16]

    9. Now let's start building our stack

        > You will notice that the first page in the building stack window contains the message we wrote in our Read Me tab in our stack. This is the same message your team will see when they build their stack. It is a good practice to include information about your project or stack for your teammates.

        Click **Next**

        ![Azure Init Stack][17]

    10. Make sure the correct credentials are selected (you can save multiple credentials) and click **Build Stack**

        ![Azure build stack][18]

        Your stack will start building..

        ![Azure stack building][19]

    11. Congratulations, your stack was built successfully, click **Start Coding**

        <!-- ![Azure stack built successfully][20] -->

        You can now start working on your new VM

        ![VM ready][21]

        You can also see your VM created on your Azure account

        ![VM on Azure][22]


[1]: https://azure.microsoft.com
[2]: https://azure.microsoft.com/en-us/services/virtual-machines/
[3]: https://azure.microsoft.com/en-us/pricing/
[4]: {{ site.url }}/assets/img/guides/azure/create-new-stack.png
[5]: {{ site.url }}/assets/img/guides/azure/azure-provider.png
[6]: {{ site.url }}/assets/img/guides/azure/azure-default-stack.png
[7]: {{ site.url }}/assets/img/guides/azure/azure-readme.png
[8]: https://msdn.microsoft.com/en-us/dynamics-nav/how-to--download-and-import-publish-settings-and-subscription-information
[9]: https://manage.windowsazure.com/publishsettings
[10]: {{ site.url }}/assets/img/guides/azure/azure-get-publish-settings.png
[11]: {{ site.url }}/assets/img/guides/azure/azure-download-publish-settings-file.png
[12]: {{ site.url }}/assets/img/guides/azure/azure-get-sub-id-1.png
[13]: {{ site.url }}/assets/img/guides/azure/azure-get-sub-id-2.png
[14]: {{ site.url }}/assets/img/guides/azure/azure-cred-complete.png
[15]: {{ site.url }}/assets/img/guides/azure/azure-save-stack.png
[16]: {{ site.url }}/assets/img/guides/azure/azure-stack-saved.png
[17]: {{ site.url }}/assets/img/guides/azure/azure-stack-build-1.png
[18]: {{ site.url }}/assets/img/guides/azure/azure-stack-build-2.png
[19]: {{ site.url }}/assets/img/guides/azure/azure-stack-building.png
<!-- [20]: -->

[21]: {{ site.url }}/assets/img/guides/azure/azure-stack-built.png
[22]: {{ site.url }}/assets/img/guides/azure/azure-backend-success.png
