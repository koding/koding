$ = require 'jquery'
assert = require 'assert'

#! b2244ac3-4d7b-48d6-aa60-239d7c7ade21
# title: editReinitPrivateStack_destroyVMs_deletePrivateStack
# start_uri: /
# tags: automated
#

describe "editReinitPrivateStack_destroyVMs_deletePrivateStack.rfml", ->
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


  describe """Click on 'CANCEL' and 'INITIALIZE' buttons respectively and wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Read Me' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'NEXT' and BUILD STACK buttons respectively""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Fetching and validating credentials...' text in a progress bar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a green progress bar also below 'aws-instance' label on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Wait for a few minutes for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Success! Your stack has been built.' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'View The Logs', 'Connect your Local Machine' and 'Invite to Collaborate' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see START CODING button on the bottom??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'STACKS' title from left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack' under 'Private Stacks' section?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that the other sections are empty??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'My Team' from left vertical menu""", ->
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

    it """Do you see '{{ random.last_name }}{{ random.number }}' label at the top left corner?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '@rainforestqa22' label below it?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS' title and 'Your stacks has not been fully configured yet, ...' text on left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'You are almost there, rainforestqa22!' title on a pop-up displayed in the center of the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your Team Stack is Pending' and 'PENDING' texts??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close that modal by clicking (x) from top right corner and click on 'STACKS' from left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see that all of the 'Team Stacks', 'Private Stacks' and 'Drafts' sections are empty??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser and click on 'Stacks' item from the left vertical menu under 'Dashboard' and click on '_Aws Stack'""", ->
    before -> 
      # implement before hook 

    it """Do you see that the stack editor is opened?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """(you can see ../Stack-Editor/.. above in the address bar) Do you see '_Aws Stack' text and 'Edit Name' link below it?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'DELETE THIS STACK TEMPLATE' and STACK SCRIPT DOCS links on the bottom of the page??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'DELETE THIS STACK TEMPLATE'""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'You currently have a stack generated from this template.' message displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Edit Name', delete the text there and enter "Team Stack" and then go to line #12, delete aws-instance and type "testmachine" instead (like in this image: http://take.ms/oxOXl) and then click on 'SAVE' button from top right and wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Have 'RE-INITIALIZE' and 'MAKE TEAM DEFAULT' buttons appeared next to 'SAVE' button?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACK UPDATED' pop-up appeared next to (1) notification on left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Team Stack' text on sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'UPDATE MY MACHINES' and then 'PROCEED' buttons respectively and wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Team Stack' title on the modal in the center of the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', 'Team Stack' and 'testmachine' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Team Stack' from left sidebar and select 'Destroy VMs' and then click on 'PROCEED' button on the 'Destroy Stack' titled pop-up and wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Is 'testmachine' label under 'Team Stack' removed from left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Create a stack for your team' text and 'CREATE A TEAM STACK' button in the center of the page??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'STACKS' title from left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Team Stack' under 'Drafts' section?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that the other sections are empty??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window and reload the page""", ->
    before -> 
      # implement before hook 

    it """Do you see that all of the 'Team Stacks', 'Private Stacks' and 'Drafts' sections are still empty??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser and click on 'Team Stack'""", ->
    before -> 
      # implement before hook 

    it """Do you see that the stack editor is opened?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """(you can see ../Stack-Editor/.. above in the address bar) Do you see 'DELETE THIS STACK TEMPLATE' and STACK SCRIPT DOCS links on the bottom of the page??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'DELETE THIS STACK TEMPLATE' and 'YES' buttons respectively""", ->
    before -> 
      # implement before hook 

    it """Is 'Team Stack' removed from left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your stacks has not been fully configured yet,' text under 'STACKS' title??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'STACKS' title from left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see that all of the 'Team Stacks', 'Private Stacks' and 'Drafts' sections are empty??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """""", ->
    before -> 
      # implement before hook 

