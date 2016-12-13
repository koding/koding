#! 53c55879-0372-4da6-86c3-a07ee8bab35d
# title: show_edit_remove_credentials
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

Click on 'Credentials' and then click on 'ADD A NEW CREDENTIAL' button on the bottom
Do you see 'Add your AWS credentials' title? Do you see 'Title', 'Access Key ID' , 'Secret Access Key' and 'Region' fields? Do you see 'CANCEL', 'ADVANCED MODE' and 'SAVE' buttons? (If buttons are not visible, scroll down until you see them)

Enter "{{ random.first_name }}" in 'Title', "{{ random.number }}" in 'Access Key ID', "{{ random.password }}" in 'Secret Access Key' fields and click on 'SAVE' button below
Is it added to the top of the list above 'rainforestqa99's AWS keys'?

Click on 'ADD A NEW CREDENTIAL' button again, enter "{{ random.last_name }}" in 'Title', "{{ random.number }}" in 'Access Key ID', "{{ random.password }}" in 'Secret Access Key' fields and click on 'SAVE' button below
Is it added to the list?

Move your mouse over '{{ random.last_name }}' text, click on 'DELETE' link appeared and then, in the popup window click on 'REMOVE CREDENTIAL' button
Is it removed from the list successfully?

Click on 'USE THIS & CONTINUE' button next to 'rainforestqa99's AWS keys' and wait for a second for process to be completed
Have you seen 'Verifying Credentials...' message displayed? Are you switched back to the first tab('_Aws Stack')? (If you're not switched and you got 'Failed to verify: operation timed out' error, click on the same button again)

Click end of the line next to the last word on line 23, hit enter (by doing this you should go to the next line) and type "touch /${var.custom_key}", hit enter again and then type "touch /${var.userInput_name}"
Do you see that (1) as a red warning appeared next to 'Custom Variables' tab?

Click on 'Custom Variables' tab and type " key: 'qa_test' " at the end of the file (like in the screenshot here: http://take.ms/DZb5a)
Have you seen that the red warning has disappeared? Do you see '# You can define your custom variables' text in the first line?

Click on '_Aws Stack' tab and then click on 'SAVE' button on top right and wait for a few seconds for that process to be completed
Do you see 'Share Your Stack_' title on a pop-up displayed? Do you see that 'Share the credentials I used for this stack with my team.' checkbox is already checked? Do you see 'CANCEL' and 'SHARE WITH THE TEAM' buttons?

Click on 'CANCEL' button and then click on 'INITIALIZE' button on the top and wait for a few seconds for process to be completed
Do you see '_Aws Stack' title? Do you see 'Instructions', 'Credentials' and 'Build Stack' sections? Do you see 'Read Me' text? Do you see 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom? Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar?

Click on the 'NEXT' button
Do you see 'Select Credentials and Other Requirements' text? Do you see 'rainforestqa99's AWS keys' label in the text box on the left side? Do you see 'New Requirements:' title and a 'Name' text box  on the right-side? Do you see '+ Create New' link below of 'AWS Credential:' section on the left side?

Click on '+ Create New' under 'Requirements:' section, enter "{{ random.first_name }}_build" in 'Title', "{{ random.first_name }}" in 'Name' fields and click on BUILD STACK button
Do you see 'Fetching and validating credentials...' text in a progress bar? Do you see a green progress bar also below 'aws-instance' label on left sidebar?

Wait for a few minutes for process to be completed
Do you see 'Success! Your stack has been built.' text? Do you see 'View The Logs', 'Connect your Local Machine' and 'Invite to Collaborate' sections? Do you see START CODING button on the bottom?

Move your mouse over 'aws-instance' label on left sidebar and click on the circle button appeared next to it
Has a pop-up appeared? Do you see 'Stacks', 'Virtual Machines' and 'Credentials' tabs on top? Do you see 'aws-inst_' under 'Virtual Machines' section? Do you see 'Edit VM Name', 'VM Power', 'Always On', 'VM Sharing' and 'Build Logs' sections under it?

Click on 'Credentials' tab
Do you see 'rainforestqa99's AWS keys' and '{{ random.first_name }}'and 'AWS' labels next to them? (If not, please scroll down until you see them) Do you see 'Custom Variables for _Aws St_' and 'CUSTOM' label next to it? Do you see '{{ random.first_name }}_build' and 'USERINPUT' label next to it? Do you see only 'SHOW' and 'REMOVE' links next to 'AWS' labeled items? Do you also see 'EDIT' next to other items?

Click on 'SHOW' next to 'rainforestqa99's AWS keys'
Do you see a 'rainforestqa99's AWS keys Preview' titled pop-up? Do you see "access_key", "acl", "ami" and other fields listed?

Close that pop-up by clicking (x) from top right corner and click on 'EDIT' next to '{{ random.first_name }}_build'
Do you see 'Edit Credential' titled pop-up? Do you see 'Title' and 'Name' titled text boxes? Do you see 'CANCEL' and 'SAVE' buttons?

Click on the 'Name' text box, delete '{{ random.first_name }}', type "test", and click on 'SAVE' button, then click on 'SHOW' link next to it
Do you see '{{ random.first_name }}_build Preview' titled pop-up? Do you see "name": "test",?

Close that pop-up by clicking (x) from top right corner, click on 'REMOVE' next to '{{ random.first_name }}' and then click on 'REMOVE CREDENTIAL' button
Is it removed successfully from the list?
