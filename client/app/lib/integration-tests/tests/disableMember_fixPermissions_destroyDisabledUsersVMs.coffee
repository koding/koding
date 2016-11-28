$ = require 'jquery'
assert = require 'assert'

#! cf8a3ed2-eb5d-4b23-b54c-64a5a47607a6
# title: disableMember_fixPermissions_destroyDisabledUsersVMs
# start_uri: /
# tags: automated
#

describe "disableMember_fixPermissions_destroyDisabledUsersVMs.rfml", ->
  before -> 
    require './create_team_with_existing_account.coffee'

  describe """Scroll the page up to 'Permissions' section, then click on the toggle button next to 'Stack Creation' (button shown in image here: http://take.ms/zLcTG)""", ->
    before -> 
      # implement before hook 

    it """Did it turn into green?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Did the label updated as 'ON'??""", -> 
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

    it """Do you see 'Your Team Stack is Pending', 'Create a Personal Stack', and 'Install KD' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'PENDING', 'CREATE' and 'INSTALL' texts next to those sections??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Create a Personal Stack' section """, ->
    before -> 
      # implement before hook 

    it """Do you see 'Select a Provider' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'amazon web services', 'VAGRANT', 'Google Cloud Platform', 'DigitalOcean', 'Azure' and 'Softlayer'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL' and 'CREATE STACK' buttons below??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


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


  describe """Click on 'Credentials' and then click on 'USE THIS & CONTINUE' button next to 'RainforestQATeam2 AWS Keys' and wait for a second for process to be completed""", ->
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


  describe """Click on '_Aws Stack' from left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Edit', 'Initialize', 'Clone' and 'Delete' options??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Initialize'""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Stack generated successfully' message displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '_Aws Stack' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'NEXT' and BUILD STACK buttons respectively""", ->
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


  describe """Return to the first browser and scroll down the page to the 'Teammates' section and click on the little down arrow next to 'Member' label of 'rainforestqa22'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Make owner', 'Make admin' and 'Disable user' options??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Disable user' and wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Permission fix required for aws-instance' titled pop-up?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL', 'FIX PERMISSIONS' and 'DON'T ASK THIS AGAIN' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'FIX PERMISSIONS' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Fixing permissions...' and 'Permissions fixed' messages displayed respectively?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that 'rainforestqa22' is moved to the bottom of the list?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Disabled' label next to it??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close the modal by clicking (x) from top right corner""", ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack_' and 'aws-instance_' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close the 'You are almost there, rainforestqa99!' titled pop-up by clicking (x) from top right corner""", ->
    before -> 
      # implement before hook 

    it """Do you see '/home/rainforestqa22' label on top of a file list next to the left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'STACKS' from left sidebar and scroll down to the end of the page""", ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack (@rainforestqa22)' under 'Disabled User Stacks' section??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close that modal by clicking (x) from top right corner, then click on '_Aws Stack (@_' from left sidebar and click on 'Destroy VMs' and 'PROCEED' respectively""", ->
    before -> 
      # implement before hook 

    it """Is it removed from left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your stacks has not been fully configured yet,_' text under 'STACKS' title??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """""", ->
    before -> 
      # implement before hook 

  describe """""", ->
    before -> 
      # implement before hook 

  describe """""", ->
    before -> 
      # implement before hook 

