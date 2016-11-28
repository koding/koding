$ = require 'jquery'
assert = require 'assert'

#! 27ddcebb-3524-433a-8bb5-3cb1f928076a
# title: createPrivateStackByAdminAndMember_enableStackCreationForMembers
# start_uri: /
# tags: automated
#

describe "createPrivateStackByAdminAndMember_enableStackCreationForMembers.rfml", ->
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


  describe """Click on 'CANCEL' button and then click on '_Aws Stack' from left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Edit', 'Initialize' and 'Make Team Default' options??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Select 'Initialize' and wait for a few seconds for process to be completed""", ->
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

    it """Do you see 'STACKS' title and 'Your stacks has not been fully configured yet,' text on left sidebar?""", -> 
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

    it """Do you see that all of the 'Team Stacks', 'Private Stacks' and 'Drafts' sections are empty?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that there's no 'Create New Stack Template' text and 'NEW STACK' button above these sections??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser and click on the toggle button next to 'Stack Creation' under 'Permissions' section (button shown in image here: http://take.ms/zLcTG)""", ->
    before -> 
      # implement before hook 

    it """Did it turn into green?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Did the label updated as 'ON'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window again and reload the page""", ->
    before -> 
      # implement before hook 

    it """Do you see that 'Create New Stack Template' text and 'NEW STACK' button appeared on top??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'NEW STACK' then click on 'amazon web services' and click on 'CREATE STACK' button""", ->
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

    it """Do you see '_Aws Stack' text under 'STACKS' title on left siderbar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Credentials' and then click on 'USE THIS & CONTINUE' button next to 'RainforestQATeam2 AWS keys' and wait for a second for process to be completed""", ->
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

    it """Do you see that 'INITIALIZE' button appeared next to 'SAVE' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'INITIALIZE' button and wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??""", -> 
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


  describe """Return to the first browser again and click on 'Stacks' from the left vertical menu and reload the page""", ->
    before -> 
      # implement before hook 

    it """Do you still see only '_Aws Stack' under 'Private Stacks' section?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that the other sections are still empty??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


