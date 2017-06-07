#! 3e012e10-a8d1-46ee-a0b2-1431bb2ec635
# title: disableUser_removePermanently
# start_uri: /
# tags: automated
#

# create_team_with_existing_account is embedded
- 1ae7b10f-f120-47de-bc67-eae94efbd491

# redirect: false
Click on 'Invite Your Team' section
Are you directed to 'Send Invites' section of 'My Team' tab? Do you see that 'Email' field of the first row is highlighted?

Enter "rainforestqa22@koding.com" in 'Email' field that's highlighted, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)
Have you seen 'Invitation is sent to rainforestqa22@koding.com' message displayed?

Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ sandbox.auth }}@{{ random.last_name }}{{ random.number }}.{{site.host}}' by pasting the url (using ctrl-v) in the address bar
Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button?

Enter "rainforestqa22" both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button
Are you successfully logged in? Do you see '{{ random.last_name }}{{ random.number }}' label at the top left corner? Do you see 'You are almost there, rainforestqa22!' title on a pop-up in the center of the page? Do you see 'Your Team Stack is Pending' text in that pop-up?

Return to the first browser, scroll down to 'Teammates' section
Do you see 'Member' label and a little down arrow next to 'rainforestqa22'?

Click on 'Member' and select 'Disable user'
Is 'Member' label next to it updated as 'Disabled'? Is it moved to the bottom of the list?

Switch to the incognito window
Do you see that you're logged out automatically? Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button? (If not, do you see 'Your access is revoked!' text?)

Enter "rainforestqa22" both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button (If you see 'Your access is revoked!' text, delete '/Banned' from the address bar above and press enter, then do the actions above)
Have you seen 'You are not allowed to access this team' warning displayed?

Return to the first browser, click on 'Disabled' label and select 'Enable user'
Is 'Disabled' label next to it updated as 'Member' again?

Switch to the incognito window and click on 'SIGN IN' button
Are you successfully logged in?

Return to the first browser, click on 'Member' and select 'Disable user'
Is 'Member' label next to it updated as 'Disabled'? Is it moved to the bottom of the list?

Click on 'Disabled' label and select 'Remove Permanently'
Is 'rainforestqa22' removed from the list?

Switch to the incognito window
Do you see that you're logged out automatically? Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button? (If not, do you see 'Your access is revoked!' text?)

Enter "rainforestqa22" both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button (If you see 'Your access is revoked!' text, delete '/Banned' from the address bar above and press enter, then do the actions above)
Have you seen 'You are not allowed to access this team' warning displayed?