$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_endcollaboration', ->
    describe "Switch back to the first window and move your mouse over the default avatar icon on the left of 'END COLLABORATION' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a popup menu with participant's name??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'END COLLABORATION' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Are you sure?' titled pop-up?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL' and 'YES' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'YES' and wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Has 'END COLLABORATION' button on the bottom changed to 'START COLLABORATION'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is 'Camera' icon removed from the bottom status bar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the incognito window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Session ended' title pop-up?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'LEAVE' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'LEAVE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'aws-instance' item removed from the left module and all panes from that VM closed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

