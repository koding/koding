$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_permission_deny', ->
    describe "Try to click 'Untitled.txt' file at the editor area and enter any text in the editor area?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you unable to select (click) this file and make any changes with it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the orange warning 'WARNING: You don't have permission to make changes. Ask for permission.'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'Ask for permissions' link?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is warning removed from the screen??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch the other browser window where you are logged in as 'rainforestqa99'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see an user icon at the left of 'END COLLABORATION' button?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'is asking for permission to make changes' popup with DENY and GRANT PERMISSIONS actions' (like http://snag.gy/591AD.jpg )??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'DENY'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is popup removed from the screen??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the incognito browser window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see red warning 'REQUEST DENIED: Host has denied your request to make changes!' at the top of the screen??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch the other browser window where you are logged in as 'rainforestqa99'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the 'END COLLABORATION' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over user icon at the left of 'END COLLABORATION' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a popup menu with 'Make Presenter' item ( http://snag.gy/0Ml1X.jpg )??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'Make Presenter'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is popup removed from the screen??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the incognito browser window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see green warning 'ACCESS GRANTED: You can make changes now!'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return the browser where you are logged in as 'rainforestqa99'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see an user icon at the left of 'END COLLABORATION' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

