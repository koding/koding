$ = require 'jquery'
assert = require 'assert'

#! 6c3961dc-43c9-4a42-92bb-cad78eb71f17
# title: tryToCreateStackWithoutPermission_viewStackbyMember_deleteStackTemplateWhenInUsebyOthers
# start_uri: /
# tags: automated
#

describe "tryToCreateStackWithoutPermission_viewStackbyMember_deleteStackTemplateWhenInUsebyOthers.rfml", ->
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

    it """Do you see 'Share Your Stack' title on a pop-up displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that 'Share the credentials I used for this stack with my team.' checkbox is already checked?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL' and 'SHARE WITH THE TEAM' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'SHARE WITH THE TEAM' button and 'YES' buttons respectively wait for a while for process to be completed""", ->
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


  describe """Click on the number notification from top left sidebar (number notification like in this image: http://take.ms/q2ZKn) and select 'Invite Teammates'""", ->
    before -> 
      # implement before hook 

    it """Do you see that you're directed to 'Send Invites' section of 'My Team' tab of a 'Dashboard'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22@koding.com" in 'Email' field that's highlighted, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)""", ->
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


  describe """Move your mouse over 'STACKS' title on left sidebar and click on (+) button appeared next to it""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'You are not allowed to create/edit stacks!' warning displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on '_Aws Stack' on left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'View Stack', 'Reinitialize', 'VMs' and 'Destroy VMs' options??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'View Stack'""", ->
    before -> 
      # implement before hook 

    it """Are you switched to a stack editor?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """(you should see '.../Stack-Editor/...' on the address bar above) Do you see '_Aws Stack' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'You must be an admin to edit this stack.' text under 'Stack Template', 'Custom Variables' and other tabs??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'STACKS' title from left sidebar and click on '_Aws Stack' under 'Team Stacks' section""", ->
    before -> 
      # implement before hook 

    it """Do you see the same stack editor and 'You must be an admin to edit this stack.' text again??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser, click on 'Stacks' from the vertical menu under 'Dashboard' title and then click on 'NEW STACK', 'amazon web services' respectively and then click on 'CREATE STACK' button""", ->
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


  describe """Click on 'Edit Name', delete the text there and enter "Team Stack" and then click on 'Credentials' tab and click on 'USE THIS & CONTINUE' button next to 'rainforestqa99's AWS keys' and wait for a second for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Verifying Credentials...' message displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Are you switched to 'Stack Template' tab?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that 'Team Stack' is added to left sidebar?""", -> 
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


  describe """Click on 'MAKE TEAM DEFAULT', 'SHARE WITH THE TEAM' and 'YES' buttons respectively and wait for a few seconds for process to be completed (if 'Stack Template is Updated' titled pop-up appears, click on 'OK')""", ->
    before -> 
      # implement before hook 

    it """Do you see that 'MAKE TEAM DEFAULT' button is disabled?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Reinitialize Default Stack' button on top of left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Reinitialize Default Stack' and 'PROCEED' buttons respectively""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Reinitializing stack...' and 'Stack reinitalized' messages displayed respectively?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Team Stack' title on the modal in the center of the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', 'Team Stack' and 'aws-instance' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'STACKS' from left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Team Stack' under 'Team Stacks' section?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '_Aws Stack' under 'Drafts' section??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on '_Aws Stack' and then click on 'DELETE THIS STACK TEMPLATE' link on the bottom""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Are you sure?' title on a pop-up displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'There is a stack generated from this template by another team member.' text below the title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL' and 'YES' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'YES' button and then click on 'STACK' from left sidebar again""", ->
    before -> 
      # implement before hook 

    it """Is '_Aws Stack' removed from 'Drafts' section?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that 'Drafts' section is empty??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window and click on 'Reinitialize Default Stack' and 'Proceed' buttons respectively""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Reinitializing stack...' and 'Stack reinitalized' messages displayed respectively?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Team Stack' title on the modal in the center of the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', 'Team Stack' and 'aws-instance' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """""", ->
    before -> 
      # implement before hook 

