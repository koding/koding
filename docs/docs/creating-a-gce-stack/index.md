---
layout: doc
title: Create a Google Compute Engine stack
permalink: /docs/creating-a-gce-stack
parent: /docs/home
---

# {{ page.title }}

## Introduction

This guide will help you build Google Compute Engine stack. [Google Cloud][1] offers many services, one of which is [Google Compute Engine][2] which delivers virtual machines running in Google's data centers and worldwide fiber network.

You can configure the number of VMs and applications installed on each VM instance. Along with configuring VM size and region.
Your new team members will be able to use your stack to build their VMs environment and start working from day one.

> You will need to have a Google Cloud account to be able to create VMs on Google Data Center. This will require you to provide your credit card information. You can sign up for a 60 day free trial and $300 in credit. Learn more about [Google Compute Engine pricing][3].

## Step by step guide

1. Click '+' sign to **Create a New Stack**

    ![Create new stack][4]

2. Choose **Google Cloud Platform** and click **Create Stack**

    ![Choose Google Cloud Platform][5]

3. Your default Google Cloud Platform stack is now created _(If you wish you can give your stack a name by clicking on **Edit Name** below your stack name)_. In this modal you will find _four tabs_:

    1.  **Stack template**: This is your stack template
    2.  **Custom variables**: to define custom variables which you can use within your stack template, values there are hidden from the non-admin team members
    3.  **Readme**: This will be the text displayed in a message box when your team builds the stack
    4.  **Credentials**: add your Google Cloud Platform credentials here

    ![Stack template][6]

4. Edit your **Readme** file to greet your team and provide them with information regarding your project or stack

    ![Readme tab][7]

5. **Setting up your Google Cloud Account**. You need to add your Google Cloud Platform account credentials to the credentials tab. To do that, login to your Google Cloud Platform account, and follow the below steps:

    1. Create a new project:

        ![GCE New project][8]

    2. Give your new Google Cloud project a name:

        ![GCE project name][9]

    3. Once created, go to your project **Dashboard**, and click **Enable and manage APIs**.

        ![GCE project dashboard][10]

        > We need to enable Google Compute Engine API to allow Koding to create VMs on your Compute Engine account.

    4. Click **Enable API**

        ![GCE Enable APIs][11]

    5. Click **Compute Engine API**

        ![GCE project APIs][12]

    6. Click **Enable** to enable Compute Engine API

        ![GCE Enable Compute Engine API][13]   

    7. If your project doesn't have Billing Enabled, you will be prompted to enable billing, click **Enable Billing** and follow the process to add your credit card information.

        > You will not be billed if you signed up for a free trial. Your credit card information is used to confirm your identity. You should be notified when your Google Cloud trial period ends. Learn more about [Google Compute Engine pricing][3].

        ![GCE Enable Billing][14]

        > Google Cloud applies resources quotas based on your usage, you may need to request quota increase, for both global and regional limit. See [more information here](https://cloud.google.com/compute/docs/resource-quotas)

    8. Once you are done with adding your billing information, go to your project **Credentials** menu and click **Create credentials**

        ![GCE Credentials][15]

    9. Choose **Service Account Key**

        ![GCE Service account][16]

    10. Choose **Compute Engine default service account** from the drop down menu and choose **JSON** option. Click **Create**

        ![GCE JSON][17]

    11. Your credential JSON file will be **downloaded** to your computer. You will use the contents of this file in your GCE Stack credentials tab. Make sure you know where it is located on your computer.

        ![GCE credentials downloaded][18]

6. Now that you have your Google Cloud credentials ready, let's add them to Koding credentials tab. Open your Stack **Credentials** tab on Koding and add your credentials information:

    1. **Title**: Give your credentials a name
    2. **Project ID**: Every project on GCE has a unique ID. Add your project's ID here. Here is a [direct link][20] to find your project ID
    3. **Service account JSON key**: copy & paste the contents of the credentials JSON file you downloaded earlier from your GCE account
    4. **Region**: choose the region you want to create your VM in

    ![GCE credentials tab][21]

    Once you are done click **Save this & continue** to verify your credentials

7. Once your credentials are saved & verified you will be directed back to your Stack template. Click **Save** on the top right

    ![GCE Save Stack][22]

8. Click **Initialize** to start your stack

    ![GCE Init Stack][23]

9. Now let's start building our stack

    > You will notice that the first page in the building stack window contains the message we wrote in our Read Me tab in our stack. This is the same message your team will see when they build their stack. It is a good practice to include information about your project or stack for your teammates.

    Click **Next**

    ![GCE Init Stack][24]

10. Make sure the correct credentials are selected (you can save multiple credentials) and click **Build Stack**

    ![GCE build stack][25]

    Your stack will start building..

    ![GCE stack building][26]

11. Congratulations, your stack was built successfully, click **Start Coding**

    ![GCE stack built successfully][27]

    You can now start working on your new VM

    ![VM ready][28]

    You can also see your VM created on your GCE account

    ![VM on GCE][29]


[1]: https://cloud.google.com/
[2]: https://cloud.google.com/compute/
[3]: https://cloud.google.com/compute/pricing
[4]: {{ site.url }}/assets/img/guides/azure/create-new-stack.png
[5]: {{ site.url }}/assets/img/guides/gce/provider-gce.png
[6]: {{ site.url }}/assets/img/guides/gce/gce-default-stack.png
[7]: {{ site.url }}/assets/img/guides/gce/gce-readme.png
[8]: {{ site.url }}/assets/img/guides/gce/gce-new-project.png
[9]: {{ site.url }}/assets/img/guides/gce/gce-create-project.png
[10]: {{ site.url }}/assets/img/guides/gce/gce-project-dashboard.png
[11]: {{ site.url }}/assets/img/guides/gce/gce-enable-api.png
[12]: {{ site.url }}/assets/img/guides/gce/gce-apis-list.png
[13]: {{ site.url }}/assets/img/guides/gce/gce-api-compute-engine.png
[14]: {{ site.url }}/assets/img/guides/gce/gce-enable-billing.png
[15]: {{ site.url }}/assets/img/guides/gce/gce-credentials.png
[16]: {{ site.url }}/assets/img/guides/gce/gce-cred-service-account-key.png
[17]: {{ site.url }}/assets/img/guides/gce/gce-cred-ce-json.png
[18]: {{ site.url }}/assets/img/guides/gce/gce-cred-created.png

[20]: https://console.cloud.google.com/iam-admin/settings
[21]: {{ site.url }}/assets/img/guides/gce/gce-add-credetnials.png
[22]: {{ site.url }}/assets/img/guides/gce/gce-save-stack.png
[23]: {{ site.url }}/assets/img/guides/gce/gce-initi-stack.png
[24]: {{ site.url }}/assets/img/guides/gce/gce-build-stack01.png
[25]: {{ site.url }}/assets/img/guides/gce/gce-build-stack02.png
[26]: {{ site.url }}/assets/img/guides/gce/gce-stack-building.png
[27]: {{ site.url }}/assets/img/guides/gce/gce-stack-built.png
[28]: {{ site.url }}/assets/img/guides/gce/gce-vm-ready.png
[29]: {{ site.url }}/assets/img/guides/gce/gce-backend-success.png
