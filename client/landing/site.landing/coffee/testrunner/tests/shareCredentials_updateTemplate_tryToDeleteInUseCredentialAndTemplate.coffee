$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_account = require './create_team_with_existing_account'

module.exports = ->

  create_team_with_existing_account()

  describe 'shareCredentials_updateTemplate_tryToDeleteInUseCredentialAndTemplate', ->
    describe "Click on 'Create a Stack for Your Team' section?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Select a Provider' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'amazon web services', 'VAGRANT', 'Google Cloud Platform', 'DigitalOcean', 'Azure', 'Marathon' and 'Softlayer'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL' and 'CREATE STACK' buttons below??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'amazon web services' and then click on 'CREATE STACK' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Has that pop-up disappeared?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '_Aws Stack' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Custom Variables', 'Readme' tabs?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Credentials' text having a red (!) next to it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '# Here is your stack preview' in the first line of main content?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'DELETE THIS STACK TEMPLATE', 'PREVIEW' and 'LOGS' buttons on the bottom and 'SAVE' button on top right??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'SAVE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Has 'You need to set your AWS credentials to be able to build this stack.' error message appeared above 'Credentials!' tab??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Credentials' and then click on 'USE THIS & CONTINUE' button next to 'rainforestqa99's AWS keys' and wait for a second for process to be completed (scroll down if you cannot see 'rainforestqa99's AWS keys')?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Verifying Credentials...' message displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Are you switched back to the first tab('_Aws Stack')?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "(If you're not switched and you got 'Failed to verify: operation timed out' error, click on the same button again)?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the 'SAVE' button on top right and wait for a few seconds for that process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Share Your Stack_' title on a pop-up displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that 'Share the credentials I used for this stack with my team.' checkbox is already checked?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL' and 'SHARE WITH THE TEAM' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the 'SHARE WITH THE TEAM' button and then click on the 'YES' button and wait for a while for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '_Aws Stack' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the 'NEXT' button and then click on the BUILD STACK button and while waiting for the process to be completed click on the number notification from top left sidebar (number notification like in this image: http://take.ms/q2ZKn)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Create a Stack', 'Enter Credentials', 'Build Your Stack' , 'Invite Teammates' and 'Install KD' options??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Invite Teammates' and enter 'rainforestqa22@koding.com' in 'Email' field that's highlighted, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Invitation is sent to rainforestqa22@koding.com' message displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ sandbox.auth }}@{{ random.last_name }}{{ random.number }}.{{site.host}}' by pasting the url (using ctrl-v) in the address bar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa22' both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you successfully logged in?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '{{ random.last_name }}{{ random.number }}' label at the top left corner?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '_Aws Stack' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the 'NEXT' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that 'Credentials' tab under '_Aws Stack' is highlighted?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Use default credential' text in a textbox under 'AWS Credential:' section??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on BUILD STACK button and wait for a few minutes for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Success! Your stack has been built.' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'View The Logs', 'Connect your Local Machine' and 'Invite to Collaborate' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see START CODING button on the bottom??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on START CODING button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '_Aws Stack' under 'STACKS' title in the left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a green square next to 'aws-instance' label?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '/home/rainforestqa22' label on top of a file list?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'cloud-init-o_' file on top and 'Terminal' tab on the bottom pane??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser, close the modal by clicking (x) from top right and then click on the little down arrow next to '_Aws Stack' from left sidebar and select 'Edit' option?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that the stack editor is opened?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "(you can see ../Stack-Editor/.. above in the address bar) Do you see '_Aws Stack' text and 'Edit Name' link next to it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'DELETE THIS STACK TEMPLATE' link on the bottom of the page??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'DELETE THIS STACK TEMPLATE'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'This template currently in use by the Team.' message displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Edit Name', delete the text there and enter 'Team Stack' and then go to line #12, rename 'aws_instance' as 'aws_machine' and then click to 'Credentials' tab?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'IN USE' tag next to 'rainforestqa99's AWS keys'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Move your mouse over 'rainforestqa99's AWS keys' text and click on 'DELETE' link that appeared?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'This credential is currently in-use' message displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that keys are not deleted??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'SAVE' button from top right and wait for a few seconds for process to be completed (if 'Stack Template is Updated' titled pop-up appears, click on 'OK')?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Has 'RE-INITIALIZE' button appeared next to 'SAVE' button?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'STACK UPDATED' pop-up appeared next to (1) notification on left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Team Stack' text on sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'UPDATE MY MACHINES' and then 'PROCEED' buttons respectively and wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Team Stack' title on the modal in the center of the page?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'STACKS', 'Team Stack' and 'aws-machine' labels on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'STACK UPDATED' pop-up appeared next to (1) notification on left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Team Stack' text on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'UPDATE MY MACHINES' and then 'PROCEED' buttons respectively and wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Reinitializing stack...' and 'Stack reinitalized' messages displayed respectively?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Team Stack' title on the modal in the center of the page?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'STACKS', 'Team Stack' and 'aws_machine' labels on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

