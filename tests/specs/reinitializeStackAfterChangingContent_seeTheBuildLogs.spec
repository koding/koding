#! 67cab4a5-5132-46a5-afa0-8f10dd8fe2c0
# title: reinitializeStackAfterChangingContent_seeTheBuildLogs
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

Click on 'CANCEL' and 'INITIALIZE' buttons respectively and wait for a while for process to be completed
Do you see '_Aws Stack' title? Do you see 'Instructions', 'Credentials' and 'Build Stack' sections? Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom? Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar?

Click on the 'NEXT' button and then click on the 'BUILD STACK'
Do you see 'Fetching and validating credentials...' text in a progress bar? Do you see a green progress bar also below 'aws-instance' label on left sidebar?

Wait for a few minutes for process to be completed
Do you see 'Success! Your stack has been built.' text? Do you see 'View The Logs', 'Connect your Local Machine' and 'Invite to Collaborate' sections? Do you see START CODING button on the bottom?

Click on START CODING button
Do you see '_Aws Stack' under 'STACKS' title in the left sidebar? Do you see a green square next to 'aws-instance' label? Do you see '/home/rainforestqa99' label on top of a file list? Do you see 'cloud-init-o_' file on top and 'Terminal' tab on the bottom pane? 

Click on the tab where it says 'Terminal', type "ls /" and hit enter
Do you see the green colored 'helloworld.txt' file in the list?

Click on the little down arrow next to '/home/rainforestqa99' label on top of file list next to left sidebar
Do you see 'Refresh', 'Collapse', 'Change top folder', 'New file', 'New folder' and 'Toggle invisible files' options?

Click on 'New file'
Is 'NewFile.txt' added to the end of the file list?

Delete 'NewFile', enter "{{ random.first_name }}" and hit enter
Is the new file saved as '{{ random.first_name }}.txt'?

Click on the tab where it says 'Terminal' again, then type "ls" and hit enter
Do you see the green colored '{{ random.first_name }}.txt' file only?

Click on the little down arrow next to '_Aws Stack' from left sidebar, then click on 'Reinitialize' and 'PROCEED' respectively
Have you seen 'Reinitializing stack...' and 'Stack reinitalized' messages displayed respectively? Do you see '_Aws Stack' title on the modal in the center of the page?

Click on the 'NEXT' button and then click on the 'BUILD STACK'
Do you see 'Fetching and validating credentials...' text in a progress bar? Do you see a green progress bar also below 'aws-instance' label on left sidebar?

Wait for a few minutes for process to be completed
Do you see 'Success! Your stack has been built.' text? Do you see 'View The Logs', 'Connect your Local Machine' and 'Invite to Collaborate' sections? Do you see START CODING button on the bottom?

Click on 'View the Logs' button
Is that success modal closed? Do you see something like in this image: http://take.ms/S2PPR? Do you see '_Aws Stack' under 'STACKS' title in the left sidebar? Do you see a green square next to 'aws-instance' label? Do you see '/home/rainforestqa99' label on top of a file list? Do you see 'cloud-init-o_' file on top and 'Terminal' tab on the bottom pane? Do you see that '{{ random.first_name }}.txt' is not listed in the file list anymore?

Click on the tab where it says 'Terminal', type "ls" and hit enter
Do you see that nothing is returned as a result and just 'rainforestqa99@rainforestqa99:~$_' is displayed?