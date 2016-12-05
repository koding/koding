$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_account = require './create_team_with_existing_account'

module.exports = ->

  create_team_with_existing_account()

  describe 'createPrivateStackByAdminAndMember_enableStackCreationForMembers', ->
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


      it "Do you see 'Share Your Stack_' title on a pop-up displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that 'Share the credentials I used for this stack with my team.' checkbox is already checked?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL' and 'SHARE WITH THE TEAM' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'CANCEL' button and then click on the little down arrow next to '_Aws Stack' from left sidebar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Edit', 'Initialize' and 'Make Team Default' options??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Select 'Initialize' and wait for a few seconds for process to be completed?", ->
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

    describe "Click on 'STACKS' title from left sidebar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '_Aws Stack' under 'Private Stacks' section?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that the other sections are empty??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'My Team' from left vertical menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Team Settings', 'Permissions' and 'Send Invites' sections??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa22@koding.com' in 'Email' field of the first row of 'Send Invites' section, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)?", ->
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

      it "Do you see 'Your Team Stack is Pending' and 'PENDING' texts??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close that modal by clicking (x) from top right corner and click on 'STACKS' from left sidebar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that all of the 'Team Stacks', 'Private Stacks' and 'Drafts' sections are empty?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that there's no 'Create New Stack Template' text and 'NEW STACK' button above these sections??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser and click on the toggle button next to 'Stack Creation' under 'Permissions' section (button shown in image here: http://take.ms/zLcTG)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did it turn into green?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Did the label updated as 'ON'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window again and reload the page?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that 'Create New Stack Template' text and 'NEW STACK' button appeared on top??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'NEW STACK' then click on 'amazon web services' and click on 'CREATE STACK' button?", ->
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

      it "Do you see '_Aws Stack' text under 'STACKS' title on left siderbar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Credentials' and then click on 'USE THIS & CONTINUE' button next to 'RainforestQATeam2 AWS keys' and wait for a second for process to be completed?", ->
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

    describe "Click on 'INITIALIZE' button and wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
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

    describe "Click on 'STACKS' title from left sidebar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '_Aws Stack' under 'Private Stacks' section?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that the other sections are empty??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser again and click on 'Stacks' from the left vertical menu and reload the page?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you still see only '_Aws Stack' under 'Private Stacks' section?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that the other sections are still empty??", (done) -> 
        assert(false, 'Not Implemented')
        done()

