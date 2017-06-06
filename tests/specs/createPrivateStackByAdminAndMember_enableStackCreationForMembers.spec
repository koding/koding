#! 27ddcebb-3524-433a-8bb5-3cb1f928076a
# title: createPrivateStackByAdminAndMember_enableStackCreationForMembers
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

Click on 'CANCEL' button and then click on the little down arrow next to '_Aws Stack' from left sidebar
Do you see 'Edit', 'Initialize' and 'Make Team Default' options?

Select 'Initialize' and wait for a few seconds for process to be completed
Do you see '_Aws Stack' title? Do you see 'Instructions', 'Credentials' and 'Build Stack' sections? Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom? Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar?

Click on 'STACKS' title from left sidebar
Do you see '_Aws Stack' under 'Private Stacks' section? Do you see that the other sections are empty?

Click on 'My Team' from left vertical menu
Do you see 'Team Settings', 'Permissions' and 'Send Invites' sections?

Enter "rainforestqa22@koding.com" in 'Email' field of the first row of 'Send Invites' section, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)
Have you seen 'Invitation is sent to rainforestqa22@koding.com' message displayed?

Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ sandbox.auth }}@{{ random.last_name }}{{ random.number }}.{{site.host}}' by pasting the url (using ctrl-v) in the address bar
Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button?

Enter "rainforestqa22" both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button
Do you see '{{ random.last_name }}{{ random.number }}' label at the top left corner? Do you see '@rainforestqa22' label below it? Do you see 'STACKS' title and 'Your stacks has not been fully configured yet,' text on left sidebar? Do you see 'You are almost there, rainforestqa22!' title on a pop-up displayed in the center of the page? Do you see 'Your Team Stack is Pending' and 'PENDING' texts?

Close that modal by clicking (x) from top right corner and click on 'STACKS' from left sidebar
Do you see that all of the 'Team Stacks', 'Private Stacks' and 'Drafts' sections are empty? Do you see that there's no 'Create New Stack Template' text and 'NEW STACK' button above these sections?

Return to the first browser and click on the toggle button next to 'Stack Creation' under 'Permissions' section (button shown in image here: http://take.ms/zLcTG)
Did it turn into green? Did the label updated as 'ON'?

Switch to the incognito window again and reload the page
Do you see that 'Create New Stack Template' text and 'NEW STACK' button appeared on top?

Click on 'NEW STACK' then click on 'amazon web services' and click on 'CREATE STACK' button
Has that pop-up disappeared? Do you see '_Aws Stack' title? Do you see 'Custom Variables', 'Readme' tabs? Do you see 'Credentials' text having a red (!) next to it? Do you see '_Aws Stack' text under 'STACKS' title on left siderbar?

Click on 'Credentials' and then click on 'USE THIS & CONTINUE' button next to 'RainforestQATeam2 AWS keys' and wait for a second for process to be completed
Have you seen 'Verifying Credentials...' message displayed? Are you switched back to the first tab('_Aws Stack')? (If you're not switched and you got 'Failed to verify: operation timed out' error, click on the same button again)

Click on the 'SAVE' button on top right and wait for a few seconds for that process to be completed
Do you see that 'INITIALIZE' button appeared next to 'SAVE' button?

Click on 'INITIALIZE' button and wait for a few seconds for process to be completed
Do you see '_Aws Stack' title? Do you see 'Instructions', 'Credentials' and 'Build Stack' sections? Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar?

Click on 'STACKS' title from left sidebar
Do you see '_Aws Stack' under 'Private Stacks' section? Do you see that the other sections are empty?

Return to the first browser again and click on 'Stacks' from the left vertical menu and reload the page
Do you still see only '_Aws Stack' under 'Private Stacks' section? Do you see that the other sections are still empty?