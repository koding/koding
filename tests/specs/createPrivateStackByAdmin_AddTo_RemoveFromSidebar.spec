#! 439855b0-c577-481c-986a-2abfad0ea3a6
# title: createPrivateStackByAdmin_AddTo_RemoveFromSidebar
# start_uri: /
# tags: automated
#

# create_team_with_existing_account is embedded
- 1ae7b10f-f120-47de-bc67-eae94efbd491

# redirect: false
Click on 'Create a Stack for Your Team' section
Do you see 'Select a Provider' title? Do you see 'amazon web services', 'VAGRANT', 'Google Cloud Platform', 'DigitalOcean', 'Azure', 'Marathon' and 'Softlayer'? Do you see 'CANCEL' and 'CREATE STACK' buttons below?

Click on 'amazon web services' and then click on 'CREATE STACK' button
Has that pop-up disappeared? Do you see '_Aws Stack' title? Do you see 'Custom Variables', 'Readme' tabs? Do you see 'Credentials' text having a red (!) next to it? Do you see '# Here is your stack preview' in the first line of main content? Do you see 'DELETE THIS STACK TEMPLATE', 'PREVIEW' and 'LOGS' buttons on the bottom and 'SAVE' button on top right?

Click on 'Credentials' and then click on 'USE THIS & CONTINUE' button next to 'rainforestqa99's AWS keys' and wait for a second for process to be completed (scroll down if you cannot see 'rainforestqa99's AWS keys')
Have you seen 'Verifying Credentials...' message displayed? Are you switched back to the first tab('_Aws Stack')? (If you're not switched and you got 'Failed to verify: operation timed out' error, click on the same button again)

Click on the 'SAVE' button on top right and wait for a few seconds for that process to be completed
Do you see 'Share Your Stack_' title on a pop-up displayed? Do you see that 'Share the credentials I used for this stack with my team.' checkbox is already checked? Do you see 'CANCEL' and 'SHARE WITH THE TEAM' buttons?

Click on 'SHARE WITH THE TEAM' and 'YES' buttons respectively and wait for a while for process to be completed
Do you see '_Aws Stack' title? Do you see 'Instructions', 'Credentials' and 'Build Stack' sections? Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom? Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar?

Click on 'STACKS' title from left sidebar
Do you see 'Create New Stack Template' text? Do you see 'NEW STACK' button next to it?

Click on 'NEW STACK', then select 'amazon web services' and click on 'CREATE STACK' button 
Do you see '_Aws Stack' title and 'Edit Name' link next to it? Do you see 'Custom Variables', 'Readme' tabs? Do you see 'Credentials' text having a red (!) next to it? Do you see that a 2nd '_Aws Stack' is added to left sidebar?

Click on 'Edit Name', delete the text there and enter "Personal Stack" and then click on 'Credentials' tab and click on 'USE THIS & CONTINUE' button next to 'rainforestqa99's AWS keys' and wait for a second for process to be completed
Have you seen 'Verifying Credentials...' message displayed? Are you switched back to the first tab('_Stack')? Do you see that 'Personal Stack' is added to left sidebar? (If you're not switched and you got 'Failed to verify: operation timed out' error, click on the same button again)

Click on the 'SAVE' button on top right and wait for a few seconds for that process to be completed
Do you see 'MAKE TEAM DEFAULT', 'INITIALIZE' and 'SAVE' buttons?

Click on 'INITIALIZE' button and wait for a few seconds for process to be completed
Do you see 'Personal Stack' title? Do you see 'Instructions', 'Credentials' and 'Build Stack' sections? Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom? Do you see 'STACKS', 'Personal Stack' and 'aws-instance-1' labels on left sidebar?

Click on the 'NEXT' button and then click on the BUILD STACK button and while waiting for the process to be completed click on the 'STACKS' from left sidebar
Do you see '_Aws Stack' under 'Team Stacks' and 'Personal Stack' under 'Private Stacks' section? Do you see 'REMOVE FROM SIDEBAR' links next to them?

Click on 'REMOVE FROM SIDEBAR' link next to 'Personal Stack'
Is the link updated as 'ADD TO SIDEBAR'? Do you see that 'Personal Stack' is removed from left sidebar when you close the pop-up by clicking (x) from top right corner?

Click on the 'STACKS' from left sidebar again and click on 'ADD TO SIDEBAR', and then click on 'My Team' from left vertical menu
Do you see 'Team Settings', 'Permissions' and 'Send Invites' sections?

Enter "rainforestqa22@koding.com" in 'Email' field of the first row of 'Send Invites' section, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)
Have you seen 'Invitation is sent to rainforestqa22@koding.com' message displayed?

Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ sandbox.auth }}@{{ random.last_name }}{{ random.number }}.{{site.host}}' by pasting the url (using ctrl-v) in the address bar
Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button?

Enter "rainforestqa22" both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button
Are you successfully logged in? Do you see '{{ random.last_name }}{{ random.number }}' label at the top left corner? Do you see '_Aws Stack' title? Do you see 'Instructions', 'Credentials' and 'Build Stack' sections? Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom? Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar?

Click on 'STACKS' from left sidebar
Do you see '_Aws Stack' under 'Team Stacks' section? Do you see that the other sections are empty?