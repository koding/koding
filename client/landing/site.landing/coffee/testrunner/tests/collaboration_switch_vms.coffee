$ = require 'jquery'
assert = require 'assert'
ide_switch_vms = require './ide_switch_vms'

module.exports = ->

  ide_switch_vms()

  describe 'collaboration_switch_vms', ->
    describe "click on team name '{{ random.last_name }}{{ random.number }}' on the left side, click on 'Dashboard' in the opening menu, click on 'My Team' then scroll down to 'Send Invites' section?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that 'Email' fields??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'rainforestqa22@koding.com' in the 'Email' field of the second row and click on 'SEND INVITES' button?", ->
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

      it "Do you see '_Aws Stack' label??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the 'NEXT' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Select Credentials' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see AWS Keys' label in a text box?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a BUILD STACK button and 'BACK TO INSTRUCTIONS' text on the bottom??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the BUILD STACK button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Fetching and validating credentials...' text in a progress bar??", (done) -> 
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

    describe "Switch the first browser and close that modal by clicking (x) from top right corner of the 'Invitations' pane?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is that pane closed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'START COLLABORATION' button in the bottom right corner?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Starting session' progress bar below the button and after that 'START COLLABORATION' button is converted to 'END COLLABORATION'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a shortened URL in the bottom status bar (like on screenshot http://snag.gy/dp1Cn.jpg )??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click shortened URL in the bottom status bar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Copied to clipboard!' popup message??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Remember the list of panes opened (terminal, untitled.txt, etc) and select the incognito window and paste copied URL in the browser address bar and press enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'SHARED VMS' label in the left module on the page?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'aws-instance' item below the 'SHARED VMS' label?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see white popup with 'Reject' and 'Accept' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'Accept' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Joining to collaboration session' progress bar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the same panes (terminal, untitled.txt) like on the browser where you are logged in as 'rainforestqa99'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return the first browser and click on 'aws-instance-1' labels on the left sidebar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'START COLLABORATION' in the bottom status bar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see files are located under correct VMs??", (done) -> 
        assert(false, 'Not Implemented')
        done()

