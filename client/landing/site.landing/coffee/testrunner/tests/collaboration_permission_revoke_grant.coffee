$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_permission_revoke_grant', ->
    describe "Switch back to main window. Mouse over user icon at the left of 'END COLLABORATION' button then click on 'Make Presenter'?", ->
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

    describe "Switch back to main window. Move mouse over to user icon at the left of 'END COLLABORATION' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a popup menu with 'Revoke Permission' item??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Revoke Permission'?", ->
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


      it "Do you see red warning 'ACCESS REVOKED: Host revoked your access to control their session!'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click close icon on the red warning?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is warning removed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Try to click 'Untitled.txt' file at the editor area and enter any text in the editor area?", ->
      before (done) -> 
        # implement before hook 
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

    describe "Click 'GRANT PERMISSIONS '?", ->
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


      it "Do you see green warning 'ACCESS GRANTED: You can make changes now!' at the top of the screen??", (done) -> 
        assert(false, 'Not Implemented')
        done()

