#! 661370e4-14d7-448d-a664-54d2a1bbdf98
# title: collaboration_start_session_invite_member
# start_uri: /
# tags: embedded
#

# create_team_with_existing_user_stack_related is embedded
- 5e284d48-6055-49c0-91ea-c73681036aca

# redirect: false
click on team name "{{ random.last_name }}{{ random.number }}" on the left side, click on 'Dashboard' in the opening menu, click on 'My Team' then scroll down to 'Send Invites' section
Do you see the form with 'Email', 'First Name', 'Last Name' and 'Admin' columns? Please SCROLL DOWN if you couldn't find 'Send Invites' section

Enter "rainforestqa22@koding.com" in the 'Email' field of the second row and click on 'SEND INVITES' button
Have you seen 'Invitation is sent to rainforestqa22@koding.com' message displayed?

Open a new incognito window by clicking on the 3 dots on the top right corner of the browser and selecting 'New Incognito Window' and then go to '{{ sandbox.auth }}@{{ random.last_name }}{{ random.number }}.{{site.host}}' by pasting the url (using ctrl-v) in the address bar
Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button?

Enter "rainforestqa22" both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button
Are you successfully logged in? Do you see '_Aws Stack' label?

Click on the 'NEXT' button
Do you see 'Select Credentials' text? Do you see 'Use default credential' label in a text box? Do you see a BUILD STACK button and 'BACK TO INSTRUCTIONS' text on the bottom?

Click on the BUILD STACK button
Do you see 'Fetching and validating credentials...' text in a progress bar?

Wait for a few minutes for process to be completed
Do you see 'Success! Your stack has been built.' text? Do you see 'View The Logs', 'Connect your Local Machine' and 'Invite to Collaborate' sections? Do you see START CODING button on the bottom?

Click on START CODING button
Do you see '_Aws Stack' under 'STACKS' title in the left sidebar? Do you see a green square next to 'aws-instance' label? Do you see '/home/rainforestqa22' label on top of a file list? Do you see 'cloud-init-o_' file on top and 'Terminal' tab on the bottom pane?

Switch to the first browser and close that modal by clicking (x) at top right corner
Is that pane closed?

Click on 'START COLLABORATION' button in the bottom right corner
Do you see a green progress bar below the button and after that progress is completed 'START COLLABORATION' button is converted to 'END COLLABORATION'? Do you see a shortened URL in the bottom status bar (like on screenshot http://snag.gy/dp1Cn.jpg )?

Click on the shortened URL in the bottom status bar
Do you see 'Collaboration link is copied to clipboard.' popup message?

Switch to the incognito window and paste copied URL in the browser address bar and press enter
Do you see 'SHARED VMS' label in the left module on the page? Do you see 'aws-instance_' item below the 'SHARED VMS' label? Do you see a white popup with 'Reject' and 'Accept' buttons?

Click on 'Accept' button
Do you see 'Joining to collaboration session...' progress bar? Do you see the same panes (terminal, untitled.txt) like on the other window where you are logged in as 'rainforestqa99'
