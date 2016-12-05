$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_account = require './create_team_with_existing_account'

module.exports = ->

  create_team_with_existing_account()

  describe 'tryToCreateStackWithoutPermission_viewStackbyMember_deleteStackTemplateWhenInUsebyOthers', ->
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


      it "Do you see 'Share Your Stack' title on a pop-up displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that 'Share the credentials I used for this stack with my team.' checkbox is already checked?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL' and 'SHARE WITH THE TEAM' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'SHARE WITH THE TEAM' button and 'YES' buttons respectively wait for a while for process to be completed?", ->
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

    describe "Click on the number notification from top left sidebar (number notification like in this image: http://take.ms/q2ZKn) and select 'Invite Teammates'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that you're directed to 'Send Invites' section of 'My Team' tab of a 'Dashboard'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa22@koding.com' in 'Email' field that's highlighted, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)?", ->
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

    describe "Move your mouse over 'STACKS' title on left sidebar and click on (+) button appeared next to it?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'You are not allowed to create/edit stacks!' warning displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the little down arrow next to '_Aws Stack' on left sidebar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'View Stack', 'Reinitialize', 'VMs' and 'Destroy VMs' options??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'View Stack'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you switched to a stack editor?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "(you should see '.../Stack-Editor/...' on the address bar above) Do you see '_Aws Stack' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'You must be an admin to edit this stack.' text under '_Aws Stack', 'Custom Variables' and other tabs??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'STACKS' title from left sidebar and click on '_Aws Stack' under 'Team Stacks' section?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the same stack editor and 'You must be an admin to edit this stack.' text again??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser, click on 'Stacks' from the vertical menu under 'Dashboard' title and then click on 'NEW STACK', 'amazon web services' respectively and then click on 'CREATE STACK' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '_Aws Stack' title and 'Edit Name' link next to it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Custom Variables', 'Readme' tabs?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Credentials' text having a red (!) next to it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that a 2nd '_Aws Stack' is added to left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Edit Name', delete the text there and enter 'Team Stack' and then click on 'Credentials' tab and click on 'USE THIS & CONTINUE' button next to 'rainforestqa99's AWS keys' and wait for a second for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Verifying Credentials...' message displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Are you switched back to the first tab('_Stack')?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that 'Team Stack' is added to left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "(If you're not switched and you got 'Failed to verify: operation timed out' error, click on the same button again)?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the 'SAVE' button on top right and wait for a few seconds for that process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'MAKE TEAM DEFAULT', 'INITIALIZE' and 'SAVE' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'MAKE TEAM DEFAULT', 'SHARE WITH THE TEAM' and 'YES' buttons respectively and wait for a few seconds for process to be completed (if 'Stack Template is Updated' titled pop-up appears, click on 'OK')?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that 'MAKE TEAM DEFAULT' button is disabled?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Reinitialize Default Stack' button on top of left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Reinitialize Default Stack' and 'PROCEED' buttons respectively?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Reinitializing stack...' and 'Stack reinitalized' messages displayed respectively?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Team Stack' title on the modal in the center of the page?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'STACKS', 'Team Stack' and 'aws-instance' labels on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'STACKS' from left sidebar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Team Stack' under 'Team Stacks' section?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '_Aws Stack' under 'Drafts' section??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on '_Aws Stack' and then click on 'DELETE THIS STACK TEMPLATE' link on the bottom?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Are you sure?' title on a pop-up displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'There is a stack generated from this template by another team member.' text below the title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL' and 'YES' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'YES' button and then click on 'STACK' from left sidebar again?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is '_Aws Stack' removed from 'Drafts' section?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that 'Drafts' section is empty??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window and click on 'Reinitialize Default Stack' and 'Proceed' buttons respectively?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Reinitializing stack...' and 'Stack reinitalized' messages displayed respectively?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Team Stack' title on the modal in the center of the page?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'STACKS', 'Team Stack' and 'aws-instance' labels on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

