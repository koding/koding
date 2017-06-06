#! 6c3961dc-43c9-4a42-92bb-cad78eb71f17
# title: tryToCreateStackWithoutPermission_viewStackbyMember_deleteStackTemplateWhenInUsebyOthers
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
Do you see 'Share Your Stack' title on a pop-up displayed? Do you see that 'Share the credentials I used for this stack with my team.' checkbox is already checked? Do you see 'CANCEL' and 'SHARE WITH THE TEAM' buttons?

Click on 'SHARE WITH THE TEAM' button and 'YES' buttons respectively wait for a while for process to be completed
Do you see '_Aws Stack' title? Do you see 'Instructions', 'Credentials' and 'Build Stack' sections? Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom? Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar?

Click on the number notification from top left sidebar (number notification like in this image: http://take.ms/q2ZKn) and select 'Invite Teammates'
Do you see that you're directed to 'Send Invites' section of 'My Team' tab of a 'Dashboard'?

Enter "rainforestqa22@koding.com" in 'Email' field that's highlighted, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)
Have you seen 'Invitation is sent to rainforestqa22@koding.com' message displayed?

Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ sandbox.auth }}@{{ random.last_name }}{{ random.number }}.{{site.host}}' by pasting the url (using ctrl-v) in the address bar
Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button?

Enter "rainforestqa22" both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button
Are you successfully logged in? Do you see '{{ random.last_name }}{{ random.number }}' label at the top left corner? Do you see '_Aws Stack' title? Do you see 'Instructions', 'Credentials' and 'Build Stack' sections? Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom? Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar?

Move your mouse over 'STACKS' title on left sidebar and click on (+) button appeared next to it
Have you seen 'You are not allowed to create/edit stacks!' warning displayed?

Click on the little down arrow next to '_Aws Stack' on left sidebar
Do you see 'View Stack', 'Reinitialize', 'VMs' and 'Destroy VMs' options?

Click on 'View Stack'
Are you switched to a stack editor? (you should see '.../Stack-Editor/...' on the address bar above) Do you see '_Aws Stack' title? Do you see 'You must be an admin to edit this stack.' text under '_Aws Stack', 'Custom Variables' and other tabs?

Click on 'STACKS' title from left sidebar and click on '_Aws Stack' under 'Team Stacks' section
Do you see the same stack editor and 'You must be an admin to edit this stack.' text again?

Return to the first browser, click on 'Stacks' from the vertical menu under 'Dashboard' title and then click on 'NEW STACK', 'amazon web services' respectively and then click on 'CREATE STACK' button
Do you see '_Aws Stack' title and 'Edit Name' link next to it? Do you see 'Custom Variables', 'Readme' tabs? Do you see 'Credentials' text having a red (!) next to it? Do you see that a 2nd '_Aws Stack' is added to left sidebar?

Click on 'Edit Name', delete the text there and enter "Team Stack" and then click on 'Credentials' tab and click on 'USE THIS & CONTINUE' button next to 'rainforestqa99's AWS keys' and wait for a second for process to be completed
Have you seen 'Verifying Credentials...' message displayed? Are you switched back to the first tab('_Stack')? Do you see that 'Team Stack' is added to left sidebar? (If you're not switched and you got 'Failed to verify: operation timed out' error, click on the same button again)

Click on the 'SAVE' button on top right and wait for a few seconds for that process to be completed
Do you see 'MAKE TEAM DEFAULT', 'INITIALIZE' and 'SAVE' buttons?

Click on 'MAKE TEAM DEFAULT', 'SHARE WITH THE TEAM' and 'YES' buttons respectively and wait for a few seconds for process to be completed (if 'Stack Template is Updated' titled pop-up appears, click on 'OK')
Do you see that 'MAKE TEAM DEFAULT' button is disabled? Do you see 'Reinitialize Default Stack' button on top of left sidebar?

Click on 'Reinitialize Default Stack' and 'PROCEED' buttons respectively
Have you seen 'Reinitializing stack...' and 'Stack reinitalized' messages displayed respectively? Do you see 'Team Stack' title on the modal in the center of the page? Do you see 'STACKS', 'Team Stack' and 'aws-instance' labels on left sidebar?

Click on 'STACKS' from left sidebar
Do you see 'Team Stack' under 'Team Stacks' section? Do you see '_Aws Stack' under 'Drafts' section?

Click on '_Aws Stack' and then click on 'DELETE THIS STACK TEMPLATE' link on the bottom
Do you see 'Are you sure?' title on a pop-up displayed? Do you see 'There is a stack generated from this template by another team member.' text below the title? Do you see 'CANCEL' and 'YES' buttons?

Click on 'YES' button and then click on 'STACK' from left sidebar again
Is '_Aws Stack' removed from 'Drafts' section? Do you see that 'Drafts' section is empty?

Switch to the incognito window and click on 'Reinitialize Default Stack' and 'Proceed' buttons respectively
Have you seen 'Reinitializing stack...' and 'Stack reinitalized' messages displayed respectively? Do you see 'Team Stack' title on the modal in the center of the page? Do you see 'STACKS', 'Team Stack' and 'aws-instance' labels on left sidebar?

