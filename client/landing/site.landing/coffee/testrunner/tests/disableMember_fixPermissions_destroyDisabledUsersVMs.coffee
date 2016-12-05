$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_account = require './create_team_with_existing_account'

module.exports = ->

  create_team_with_existing_account()

  describe 'disableMember_fixPermissions_destroyDisabledUsersVMs', ->
    describe "Click on 'Invite Your Team' section, then enter 'rainforestqa22@koding.com' in 'Email' field that's highlighted, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Invitation is sent to rainforestqa22@koding.com' message displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Scroll the page up to 'Permissions' section, then click on the toggle button next to 'Stack Creation' (button shown in image here: http://take.ms/zLcTG)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did it turn into green?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Did the label updated as 'ON'??", (done) -> 
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


      it "Do you see '{{ random.last_name }}{{ random.number }}' label at the top left corner?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '@rainforestqa22' label below it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'STACKS' title and 'Your stacks has not been fully configured yet,' text on left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'You are almost there, rainforestqa22!' title on a pop-up displayed in the center of the page?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Your Team Stack is Pending', 'Create a Personal Stack', and 'Install KD' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'PENDING', 'CREATE' and 'INSTALL' texts next to those sections??", (done) -> 
        assert(false, 'Not Implemented')
        done()

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

    describe "Click on 'Credentials' and then click on 'USE THIS & CONTINUE' button next to 'RainforestQATeam2 AWS Keys' and wait for a second for process to be completed?", ->
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


      it "Do you see that 'INITIALIZE' button appeared next to 'SAVE' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the little down arrow next to '_Aws Stack' from left sidebar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Edit', 'Initialize', 'Clone' and 'Delete' options??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Initialize'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Stack generated successfully' message displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '_Aws Stack' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'NEXT' and BUILD STACK buttons respectively?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Fetching and validating credentials...' text in a progress bar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a green progress bar also below 'aws-instance' label on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Wait for a few minutes for process to be completed?", ->
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

    describe "Return to the first browser and scroll down the page to the 'Teammates' section and click on the little down arrow next to 'Member' label of 'rainforestqa22'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Make owner', 'Make admin' and 'Disable user' options??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Disable user' and wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Permission fix required for aws-instance' titled pop-up?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL', 'FIX PERMISSIONS' and 'DON'T ASK THIS AGAIN' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'FIX PERMISSIONS' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Fixing permissions...' and 'Permissions fixed' messages displayed respectively?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that 'rainforestqa22' is moved to the bottom of the list?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Disabled' label next to it??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close the modal by clicking (x) from top right corner?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '_Aws Stack_' and 'aws-instance_' labels on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close the 'You are almost there, rainforestqa99!' titled pop-up by clicking (x) from top right corner?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '/home/rainforestqa22' label on top of a file list next to the left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'STACKS' from left sidebar and scroll down to the end of the page?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '_Aws Stack (@rainforestqa22)' under 'Disabled User Stacks' section??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close that modal by clicking (x) from top right corner, then click on '_Aws Stack (@_' from left sidebar and click on 'Destroy VMs' and 'PROCEED' respectively?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is it removed from left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Your stacks has not been fully configured yet,_' text under 'STACKS' title??", (done) -> 
        assert(false, 'Not Implemented')
        done()

