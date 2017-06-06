#! d2369902-0587-4307-ba63-7356a2873a78
# title: collaboration_switch_vms
# start_uri: /
# tags: automated

# ide_switch_vms is embedded
- a8cdb653-6e46-4e0f-885a-e921684a22f7

# redirect: false
click on team name "{{ random.last_name }}{{ random.number }}" on the left side, click on 'Dashboard' in the opening menu, click on 'My Team' then scroll down to 'Send Invites' section
Do you see that 'Email' fields?

Enter "rainforestqa22@koding.com" in the 'Email' field of the second row and click on 'SEND INVITES' button
Have you seen 'Invitation is sent to rainforestqa22@koding.com' message displayed?

Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ sandbox.auth }}@{{ random.last_name }}{{ random.number }}.{{site.host}}' by pasting the url (using ctrl-v) in the address bar
Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button?

Enter "rainforestqa22" both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button
Are you successfully logged in? Do you see '_Aws Stack' label?

Click on the 'NEXT' button
Do you see 'Select Credentials' text? Do you see AWS Keys' label in a text box? Do you see a BUILD STACK button and 'BACK TO INSTRUCTIONS' text on the bottom?

Click on the BUILD STACK button
Do you see 'Fetching and validating credentials...' text in a progress bar?

Wait for a few minutes for process to be completed
Do you see 'Success! Your stack has been built.' text? Do you see 'View The Logs', 'Connect your Local Machine' and 'Invite to Collaborate' sections? Do you see START CODING button on the bottom?

Click on START CODING button
Do you see '_Aws Stack' under 'STACKS' title in the left sidebar? Do you see a green square next to 'aws-instance' label? Do you see '/home/rainforestqa22' label on top of a file list? Do you see 'cloud-init-o_' file on top and 'Terminal' tab on the bottom pane? 

Switch the first browser and close that modal by clicking (x) from top right corner of the 'Invitations' pane
Is that pane closed?

Click 'START COLLABORATION' button in the bottom right corner
Do you see 'Starting session' progress bar below the button and after that 'START COLLABORATION' button is converted to 'END COLLABORATION'? Do you see a shortened URL in the bottom status bar (like on screenshot http://snag.gy/dp1Cn.jpg )?

Click shortened URL in the bottom status bar
Do you see 'Collaboration link is copied to clipboard.' popup message?

Remember the list of panes opened (terminal, untitled.txt, etc) and select the incognito window and paste copied URL in the browser address bar and press enter
Do you see 'SHARED VMS' label in the left module on the page? Do you see 'aws-instance' item below the 'SHARED VMS' label? Do you see white popup with 'Reject' and 'Accept' buttons?

Click 'Accept' button
Do you see 'Joining to collaboration session' progress bar? Do you see the same panes (terminal, untitled.txt) like on the browser where you are logged in as 'rainforestqa99'

Return the first browser and click on 'aws-instance-1' labels on the left sidebar
Do you see 'START COLLABORATION' in the bottom status bar? Do you see files are located under correct VMs?
