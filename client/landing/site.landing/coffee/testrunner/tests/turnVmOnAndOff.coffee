$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_account = require './create_team_with_existing_account'

module.exports = ->

  create_team_with_existing_account()

  describe 'turnVmOnAndOff', ->
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

      it "Do you see a green progress bar below 'aws-instance' label on left sidebar??", (done) -> 
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

    describe "Click on START CODING, then move your mouse over 'aws-instance' label on left sidebar and click on the circle button appeared next to it?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Has a pop-up appeared?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Stacks', 'Virtual Machines' and 'Credentials' tabs on top?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'aws-inst_' under 'Virtual Machines' section?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Edit VM Name', 'VM Power', 'Always On', 'VM Sharing' and 'Build Logs' sections under it??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the toggle button that's in 'ON' state, next to 'VM Power' and wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is the label updated as 'OFF'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is it turned to gray?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Has a red progress bar appeared below 'aws-inst_' label and then disappeared after the process is completed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the same toggle button again (next to 'VM Power')?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is the label updated as 'ON'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is it turned to green?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Has a green progress bar appeared below 'aws-inst_' label??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close the pop-up by clicking on (x) from top right corner?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Boot Virtual Machine' titled pop-up?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Spinning up aws-instance' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a blue progress bar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Wait for a few minutes for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Your VM has finished Booting' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'START USING MY VM' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'START USING MY VM' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '_Aws Stack' under 'STACKS' title in the left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a green square next to 'aws-instance' label?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '/home/rainforestqa99' label on top of a file list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Move your mouse over 'aws-instance' label on left sidebar and click on the circle button appeared next to it again?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Stacks', 'Virtual Machines' and 'Credentials' tabs on top?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'aws-inst_' under 'Virtual Machines' section?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Edit VM Name', 'VM Power', 'Always On', 'VM Sharing' and 'Build Logs' sections under it??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the toggle button that's in 'ON' state, next to 'VM Power' and then close the modal by clicking (x) from top right corner?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Turn Off VM' titled pop-up in the center of the page?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'aws-instance is Being Turned Off' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Stopping VM...' text in a red progress bar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "(if the process is already completed it's OK that you don't see the previous items and 'Boot Virtual Machine' titled pop-up instead)?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Boot Virtual Machine' titled pop-up?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Let's Boot up aws-instance' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'TURN VM ON' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'TURN VM ON' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Boot Virtual Machine' titled pop-up?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Spinning up aws-instance' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a blue progress bar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Wait for a few minutes for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Your VM has finished Booting' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'START USING MY VM' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

