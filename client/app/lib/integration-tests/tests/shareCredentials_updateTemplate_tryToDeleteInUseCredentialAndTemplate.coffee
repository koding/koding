$ = require 'jquery'
assert = require 'assert'

#! 28ba6a72-547b-4e09-b2d9-60fdef4cd3f8
# title: shareCredentials_updateTemplate_tryToDeleteInUseCredentialAndTemplate
# start_uri: /
# tags: automated
#

describe "shareCredentials_updateTemplate_tryToDeleteInUseCredentialAndTemplate.rfml", ->
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


  describe """Click on 'SAVE' button""", ->
    before -> 
      # implement before hook 

    it """Has 'You need to set your AWS credentials to be able to build this stack.' error message appeared above 'Credentials!' tab??""", -> 
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


  describe """Click on the 'SHARE WITH THE TEAM' button and then click on the 'YES' button and wait for a while for process to be completed""", ->
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


  describe """Click on the 'NEXT' button and then click on the BUILD STACK button and while waiting for the process to be completed click on the number notification from top left sidebar (number notification like in this image: http://take.ms/q2ZKn)""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Create a Stack', 'Enter Credentials', 'Build Your Stack' , 'Invite Teammates' and 'Install KD' options??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Invite Teammates' and enter "rainforestqa22@koding.com" in 'Email' field that's highlighted, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)""", ->
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


  describe """Click on the 'NEXT' button""", ->
    before -> 
      # implement before hook 

    it """Do you see that 'Credentials' tab under '_Aws Stack' is highlighted?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Use default credential' text in a textbox under 'AWS Credential:' section??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on BUILD STACK button and wait for a few minutes for process to be completed""", ->
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


  describe """Click on START CODING button""", ->
    before -> 
      # implement before hook 

    it """Do you see '_Aws Stack' under 'STACKS' title in the left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a green square next to 'aws-instance' label?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '/home/rainforestqa22' label on top of a file list?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'cloud-init-o_' file on top and 'Terminal' tab on the bottom pane??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser, close the modal by clicking (x) from top right and then click on '_Aws Stack' from left sidebar and select 'Edit' option""", ->
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

    it """Have you seen 'This template currently in use by the Team.' message displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Edit Name', delete the text there and enter "Team Stack" and then go to line #12, rename 'aws_instance' as 'aws_machine' and then click to 'Credentials' tab""", ->
    before -> 
      # implement before hook 

    it """Do you see 'IN USE' tag next to 'rainforestqa99's AWS keys'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Move your mouse over 'rainforestqa99's AWS keys' text and click on 'DELETE' link that appeared""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'This credential is currently in-use' message displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that keys are not deleted??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'SAVE' button from top right and wait for a few seconds for process to be completed (if 'Stack Template is Updated' titled pop-up appears, click on 'OK')""", ->
    before -> 
      # implement before hook 

    it """Has 'RE-INITIALIZE' button appeared next to 'SAVE' button?""", -> 
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

    it """Do you see 'STACKS', 'Team Stack' and 'aws-machine' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window""", ->
    before -> 
      # implement before hook 

    it """Do you see 'STACK UPDATED' pop-up appeared next to (1) notification on left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Team Stack' text on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'UPDATE MY MACHINES' and then 'PROCEED' buttons respectively and wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Reinitializing stack...' and 'Stack reinitalized' messages displayed respectively?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Team Stack' title on the modal in the center of the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', 'Team Stack' and 'aws_machine' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


