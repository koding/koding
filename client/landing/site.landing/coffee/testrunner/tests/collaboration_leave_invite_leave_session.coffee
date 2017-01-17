$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_leave_invite_leave_session', ->
    describe "Click  'LEAVE SESSION' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Are you sure?' modal?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'YES', 'CANCEL' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'YES'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are 'aws-instance' item removed from the left module and all panes from that VM closed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch the other browser window where you are logged in as 'rainforestqa99'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the only 'camera' icon at the left of 'END COLLABORATION' button without any other icons/avatars??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click shortened URL in the bottom status bar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Copied to clipboard!' popup message??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch the incognito window and paste copied URL in the browser address bar and press enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Wait until you see 'SHARED VMS' label in the left module?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'aws-instance_' item below the 'SHARED VMS' label?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a white popup and two buttons named 'Reject' and 'Accept'??", (done) -> 
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

    describe "Click on 'LEAVE SESSION' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Are you sure?' dialog??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'YES'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'aws-instance_' under 'Shared VM's section removed from the left module and all panes from that VM closed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch the other browser window where you are logged in as 'rainforestqa99'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the only 'camera' icon at the left of 'END COLLABORATION' button without any other icons/avatars??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'END COLLABORATION' button and click 'Yes' on the 'Are you sure?' dialog?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'END COLLABORATION' button changed to 'START COLLABORATION'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is 'Camera' icon removed from the bottom status bar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

