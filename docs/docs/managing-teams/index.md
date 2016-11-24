# **Managing Teams**

In this guide, we'll cover the following actions:

1.  [**Changing Team Name**](#changing-team-name)
2.  [**Setting/Changing Team Logo**](#changing-team-logo)
3.  [**Leaving the Team**](#leaving-team)
4.  [**Team Permissions**](#team-permissions)
5.  [**Inviting New Members**](#inviting-members)
6.  [**Assigning Roles/Disabling Members**](#assigning-roles)

> All of these actions can be done from the **My Team** screen in your Dashboard, which can be found (once you are logged in) by clicking on your team name in the extreme top corner of the screen and selecting **Dashboard** from the expanded list.
<div></div>
> Only the Owner and Admins can make any of these changes in the Dashboard. The only exception is Inviting Team Members, but only if this has been enabled in Team Permissions. Learn more about these roles in Assigning Roles.

* * *

## <a name="changing-team-name"></a>**Changing Team Name**

1.  Select **My Team** in your **Dashboard**. 
2.  The first section in this screen is **Team Settings**. There you will see an input for **Team Name**. You can change this to whatever you like.
3.  Be sure to click **Change Team Name** in the bottom right corner of the section to commit the change.

> **Caution:** This will not change the Team URL!

* * *

## <a name="changing-team-logo"></a>**Setting/Changing Team Logo**

1.  Select **My Team** in your **Dashboard**. 
2.  The first section in this screen is **Team Settings**. If you haven't uploaded a Team Logo, you will see a placeholder image and an option to **Upload Logo Image**. Clicking either of those will allow you to select an image from your local machine to upload. 
3.  The Team Logo will immediately populate to the UI. If you like it, keep it! If not, click **Delete Logo** beneath the preview of the image. You can also **Remove Logo**.

> The image you select can be in any dimensions, but square images tend to work best! 

* * *

## <a name="leaving-team"></a>**Leaving the Team**

1.  Select **My Team** in your **Dashboard**. 
2.  The first section in this screen is **Team Settings**. You'll see the option here to **Leave Team**. Clicking this will open up a confirmation screen that will require you to re-type your password.
3.  Click **Confirm** to permanently leave the team. 

> **Caution:** Leaving your team will prevent you from logging in until you are invited to a new team or create your own!
<div></div>
> The Team's Owner cannot leave the team until they assign another team member as the new Owner. 

* * *

## <a name="team-permissions"></a>**Team Permissions**

1.  Select **My Team** in your **Dashboard**. 
2.  The second section in this screen is **Permissions**. There you will see two switches:  **Stack Creation** and **See/Invite team members**. 
3.  Toggling on **Stack Creation** will allow Team Members to create Stacks and will enable the Create New Stack Template section in Dashboard > Stacks for them.
4.  Toggling on **See/Invite team members** will allow Team Members to see one another and will enable the two invitation sections (Send Invites and Invite Using Slack) for them.

> Team Permissions only affect Members. The Owner and Admins will have all permissions enabled, regardless of what you enable or disable here. 

* * *

## <a name="inviting-members"></a>**Inviting Team Members**

1.  Select **My Team** in your **Dashboard**. 
2.  The third and fourth sections in this screen are **Send Invites** and **Invite Using Slack**. 
3.  To **Send Invites**, add the E-mail address and (optionally) the First/Last Name of those you wish to invite. Additionally, the Owner and Admins will see a checkbox allowing them to set these new members as Admins. Alternately, you can click **Upload CSV** to add team members from a file (clicking on **Upload CSV** will explain the process and provide an example of how the text in the file should look). In either case, click **Send Invites** to send out invitation emails to everyone on your list. They will be prompted to Sign Up or Login to Koding and will be added to your team!
4.  Alternately, clicking **Invite Using Slack** will prompt you to log into your Slack team and authorize Koding to access information about them. When this is done, this section will populate with a list of team members to invite, as well as the option to invite all members of your Slack Channels. Connecting to a Slack Team will also create the option to **Change Slack Team**.

* * *

## <a name="assigning-roles"></a>**Assigning Roles/Disabling Members**

1.  Select **My Team** in your **Dashboard**. 
2.  The fifth section in this screen is **Teammates**. This section will list all Teammates and will specify their Roles. Owners and Admins will have the option of changing their roles or disabling them.
3.  Clicking the dropdown next to each Member will offer a list of options (**Make Owner, Make Admin, Make Member, Disable User**). Selecting any of these will immediately change the role for that user. The user will see a dialog on their screen informing them of the change and prompting them to reload their UI to reflect the changes. 
4.  When users are disabled, their VMs become immediately unusable. Anyone using them will see a dialog notifying them of the change. The Owner and Admin will be given an option to 'Fix Permissions' and re-enable the user. If this is not done, they will be taken out of that interface. 
5.  Disabled users have a new dropdown menu with a new list of options (**Remove Permanently, Re-enable User**). Re-enabled users will immediately resume whatever role they previously held. Permanently removed users will be deleted along with all of their resources. 

> **Caution:** Team You can re-enable users that have been Disabled, but 'Remove Permanently' cannot be undone!