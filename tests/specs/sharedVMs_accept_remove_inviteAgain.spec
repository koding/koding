#! c1037c00-d213-4fda-ab35-e2d6adae95ad
# title: sharedVMs_accept_remove_inviteAgain
# start_uri: /
# tags: automated
#

# enable_VM_sharing_invite_Member is embedded
- 2f953286-4d03-47aa-9665-b80e2cd03c5a

# redirect: false
Click on 'ACCEPT' button
Do you see '/home/rainforestqa99' label on top of a file list next to left sidebar? Do you see 'Terminal' tab on the bottom? Do you see 'rainforestqa99@rainforestqa99:~$' in that 'Terminal' tab? 

Click on 'STACKS' title from left sidebar and switch to 'Virtual Machines' tab on top of the pop-up displayed
Do you see 'test' under 'Shared Machines' section? Do you see 'SHARED MACHINE' label next to it?

Close that pop-up by clicking (x) from top right corner, return to the first browser and move your mouse over 'rainforestqa22'
Do you see a red (x) appeared next to it?

Click on (x) that has appeared
Is 'rainforestqa22' removed from the list? Do you see 'This VM has not yet been shared with anyone.' text?

Switch to the incognito window
Do you see a pop-up with 'Machine access revoked' title? Do you see 'Your access to this machine has been removed by its owner.' text? Do you see 'OK' button?

Click on 'OK'
Are you swithced to '_Aws Stack'? Do you see that 'test' is removed from left sidebar? Do you see that '/home/rainforestqa99' label and 'Terminal' tab are not displayed anymore?

Return to the first browser, enter 'rainforestqa22' in the text box, hit enter and wait for a few seconds for process to be completed
Is 'rainforestqa22' added below 'Type a username' text box? Is 'This VM has not yet been shared with anyone.' text removed?

Switch to the incognito window
Do you see 'test(@rainforestqa99)' below 'SHARED VMS' title on left sidebar? Do you see a pop-up appeared next to it? Do you see 'wants to share their VM with you.' text in that pop-up? Do you also see 'REJECT' and 'ACCEPT' buttons?
