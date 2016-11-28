$ = require 'jquery'
assert = require 'assert'

#! 439855b0-c577-481c-986a-2abfad0ea3a6
# title: createPrivateStackByAdmin_AddTo_RemoveFromSidebar
# start_uri: /
# tags: automated
#

describe "createPrivateStackByAdmin_AddTo_RemoveFromSidebar.rfml", ->
  before -> 
    require './create_team_with_existing_account.coffee'

  describe """Click on 'amazon web services' and then click on 'CREATE STACK' button""", ->
    before -> 
      # implement before hook 

    it """Has that pop-up disappeared?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '_Aws Stack' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Stack Template', 'Custom Variables', 'Readme' tabs?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Credentials' text having a red (!) next to it?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '# Here is your stack preview' in the first line of main content?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'PREVIEW', 'LOGS', 'DELETE THIS STACK TEMPLATE' buttons on the bottom and 'SAVE' button on top right??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Credentials' and then click on 'USE THIS & CONTINUE' button next to 'rainforestqa99's AWS keys' and wait for a second for process to be completed (scroll down if you cannot see 'rainforestqa99's AWS keys')""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Verifying Credentials...' message displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Are you switched to 'Stack Template' tab?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """(If you're not switched and you got 'Failed to verify: operation timed out' error, click on the same button again)?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'SAVE' button on top right and wait for a few seconds for that process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Share Your Stack_' title on a pop-up displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that 'Share the credentials I used for this stack with my team.' checkbox is already checked?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL' and 'SHARE WITH THE TEAM' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'SHARE WITH THE TEAM' and 'YES' buttons respectively and wait for a while for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'STACKS' title from left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Create New Stack Template' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'NEW STACK' button next to it??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'NEW STACK', then select 'amazon web services' and click on 'CREATE STACK' button """, ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack' title and 'Edit Name' link below it?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Stack Template', 'Custom Variables', 'Readme' tabs?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Credentials' text having a red (!) next to it?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that a 2nd '_Aws Stack' is added to left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Edit Name', delete the text there and enter "Personal Stack" and then click on 'Credentials' tab and click on 'USE THIS & CONTINUE' button next to 'rainforestqa99's AWS keys' and wait for a second for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Verifying Credentials...' message displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Are you switched to 'Stack Template' tab?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that 'Personal Stack' is added to left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """(If you're not switched and you got 'Failed to verify: operation timed out' error, click on the same button again)?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'SAVE' button on top right and wait for a few seconds for that process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'MAKE TEAM DEFAULT', 'INITIALIZE' and 'SAVE' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'INITIALIZE' button and wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Personal Stack' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', 'Personal Stack' and 'aws-instance-1' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'NEXT' button and then click on the BUILD STACK button and while waiting for the process to be completed click on the 'STACKS' from left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack' under 'Team Stacks' and 'Personal Stack' under 'Private Stacks' section?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'REMOVE FROM SIDEBAR' links next to them??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'REMOVE FROM SIDEBAR' link next to 'Personal Stack'""", ->
    before -> 
      # implement before hook 

    it """Is the link updated as 'ADD TO SIDEBAR'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that 'Personal Stack' is removed from left sidebar when you close the pop-up by clicking (x) from top right corner??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'STACKS' from left sidebar again and click on 'ADD TO SIDEBAR', and then click on 'My Team' from left vertical menu""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Team Settings', 'Permissions' and 'Send Invites' sections??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22@koding.com" in 'Email' field of the first row of 'Send Invites' section, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Invitation is sent to rainforestqa22@koding.com' message displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ sandbox.auth }}@{{ random.last_name }}{{ random.number }}.{{site.host}}' by pasting the url (using ctrl-v) in the address bar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22" both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button""", ->
    before -> 
      # implement before hook 

    it """Are you successfully logged in?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '{{ random.last_name }}{{ random.number }}' label at the top left corner?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '_Aws Stack' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'STACKS' from left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack' under 'Team Stacks' section?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that the other sections are empty??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


