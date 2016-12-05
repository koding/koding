$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_account = require './create_team_with_existing_account'

module.exports = ->

  create_team_with_existing_account()

  describe 'editReinitPrivateStack_destroyVMs_deletePrivateStack', ->
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

    describe "Click on 'CANCEL' and 'INITIALIZE' buttons respectively and wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '_Aws Stack' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Read Me' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the 'NEXT' and BUILD STACK buttons respectively?", ->
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

      it "Do you see 'STACKS' title and 'Your stacks has not been fully configured yet, ...' text on left sidebar?", (done) -> 
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


      it "Do you see that all of the 'Team Stacks', 'Private Stacks' and 'Drafts' sections are empty??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser and click on 'Stacks' item from the left vertical menu under 'Dashboard' and click on '_Aws Stack'?", ->
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


      it "Have you seen 'You currently have a stack generated from this template.' message displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Edit Name', delete the text there and enter 'Team Stack' and then go to line #12, delete aws-instance and type 'testmachine' instead (like in this image: http://take.ms/oxOXl) and then click on 'SAVE' button from top right and wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have 'RE-INITIALIZE' and 'MAKE TEAM DEFAULT' buttons appeared next to 'SAVE' button?", (done) -> 
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

      it "Do you see 'STACKS', 'Team Stack' and 'testmachine' labels on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Team Stack' from left sidebar and select 'Destroy VMs' and then click on 'PROCEED' button on the 'Destroy Stack' titled pop-up and wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'testmachine' label under 'Team Stack' removed from left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Create a stack for your team' text and 'CREATE A TEAM STACK' button in the center of the page??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'STACKS' title from left sidebar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Team Stack' under 'Drafts' section?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that the other sections are empty??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window and reload the page?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that all of the 'Team Stacks', 'Private Stacks' and 'Drafts' sections are still empty??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser and click on 'Team Stack'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that the stack editor is opened?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "(you can see ../Stack-Editor/.. above in the address bar) Do you see 'DELETE THIS STACK TEMPLATE' link on the bottom of the page??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'DELETE THIS STACK TEMPLATE' and 'YES' buttons respectively?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Team Stack' removed from left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Your stacks has not been fully configured yet,' text under 'STACKS' title??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'STACKS' title from left sidebar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that all of the 'Team Stacks', 'Private Stacks' and 'Drafts' sections are empty??", (done) -> 
        assert(false, 'Not Implemented')
        done()

