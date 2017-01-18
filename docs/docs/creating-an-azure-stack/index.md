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

1. Click **STACKS**

    ![Create a new stack][4]

2. Click **New Stack**

    ![Click new stack][5]

3. Choose **Azure** and click **Create Stack**

    ![Choose Azure][55]

4. You will now see the default stack template for Azure. You can give your stack a name by clicking on the **Edit Name** on top beside your stack title. The _three tabs_ represent:

    1.  **Custom variables**: define custom variables to use in your stack template, hidden from Team _members_
    2.  **Readme**: this text will be shown in a message box when your team starts to build this stack. You can add instructions or notes for your team to read
    3.  **Credentials**: add your Azure account credentials here

    ![Stack template][6]

    Review the **Stack Template** file to add/modify/remove any of your VM configurations

    >You can add commands to run once your VM starts under the **user_data** section. For example you can choose to install services/packages once a VM starts. Commands under the **user_data** section will run as `root` when the VM boots.

    >Click on the stack name to return to your **Stack template editor**.

5.  Edit your **Readme** section to greet your team and provide them with information or instructions. You can use [markdown](https://en.wikipedia.org/wiki/Markdown) format

    ![Readme tab][7]

6.  Go to the **Credentials** tab and click **Add A New Credentials**

    ![Credentials][75]

7. For this step you will need to have your Azure account **Publish Settings** file contents and **Subscription ID**. To do that, login to your Azure account and follow the below steps:

    > If you haven't created an account yet, please visit [Azure website][1] to create one now.

    1. First, get your **Publish Settings** file by following the [steps in this URL][8], or open this link directly [https://manage.windowsazure.com/publishsettings][9]. Your **Publish Settings** file will be downloaded to your computer, make sure you know its location as you will need to copy its contents later

        ![Azure download publish settings file][11]

    2. To get your **Subscription ID** go to your Account Billing information [https://account.windowsazure.com/Subscriptions](https://account.windowsazure.com/Subscriptions), sign in, then:

        - Click **ACCOUNT** -> **Subscriptions** and click on your subscription plan

        ![Azure get your subscription ID][12]

        > Please note that you need to be at least on the Pay-as-you-go or developer trial. The Free trial has some limitations and may not allow your stack to build successfully. [See subscription offers](https://account.windowsazure.com/signup?showCatalog=True)

        - Scroll down to your **Subscription ID**

        ![Azure copy your subscription ID][13]

    3. Now that you have your credentials information ready, go back to your credentials tab on Koding for Teams, copy the contents of your downloaded **Publish Settings** file and paste it in your Koding credentials tab. Also paste your **Subscription ID**

        1. **Title**: Give your credentials a name
        2. **Publish Settings**: copy & paste the contents of the downloaded **Publish Settings** file here
        3. **Subscription ID**: your subscription ID on Azure that you fetched earlier
        4. **Location**: choose the region you want to create your VM in
        5. **Storage**: replication option for your Azure data [learn more here](https://docs.microsoft.com/en-us/azure/storage/storage-redundancy)

        ![Azure credentials][14]

        Once you are done click **Save this & continue** to verify your credentials

8. Once your credentials are saved & verified you will be directed back to your Stack template. Click **Save** on the top right

    ![Azure Save Stack][15]

9. Click **Initialize** to start your stack

    > You can have multiple stacks within a team, click **Make Team Default** when you want to make this stack your team's default stack.

    ![Azure Init Stack][16]

10. Now let's start building our stack

    > You will notice that the first page in the building stack window contains the message we wrote in our Read Me tab in our stack. This is the same message your team will see when they build their stack. It is a good practice to include information about your project or stack for your teammates.

    Click **Next**

    ![Azure Init Stack][17]

11. Make sure the correct credentials are selected (you can save multiple credentials) and click **Build Stack**

    ![Azure build stack][18]

    Your stack will start building..

    ![Azure stack building][19]

12. Your stack was built successfully, click **Start Coding**

    ![Azure stack built successfully][20]

    Congratulations, you can now start working on your new VM

    ![VM ready][21]

    You can also see your VM created on your Azure account

    ![VM on Azure][22]


[1]: https://azure.microsoft.com
[2]: https://azure.microsoft.com/en-us/services/virtual-machines/
[3]: https://azure.microsoft.com/en-us/pricing/
[4]: {{ site.url }}/assets/img/guides/azure/click-stacks.png
[5]: {{ site.url }}/assets/img/guides/azure/click-new-stack.png
[55]: {{ site.url }}/assets/img/guides/azure/azure-provider.png
[6]: {{ site.url }}/assets/img/guides/azure/azure-default-stack.png
[7]: {{ site.url }}/assets/img/guides/azure/azure-readme.png
[75]: {{ site.url }}/assets/img/guides/azure/azure-new-credentials.png
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
[20]: {{ site.url }}/assets/img/guides/azure/azure-stack-built.png
[21]: {{ site.url }}/assets/img/guides/azure/azure-vm-ready.png
[22]: {{ site.url }}/assets/img/guides/azure/azure-backend-success.png
