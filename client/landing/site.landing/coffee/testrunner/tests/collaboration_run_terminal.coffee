$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_run_terminal', ->
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


      it "Do you see green warning 'ACCESS GRANTED: You can make changes now!'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "You can close the warning message by clicking to (x) at right end.?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click '+' icon at the right of terminal and select New Terminal -> New Session (http://snag.gy/UnOoo.jpg)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new terminal tab opened??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Type 'sudo' in terminal and press Enter, type 'la' in terminal and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see results of the commands in the terminal??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the other browser window where you are logged in as 'rainforestqa99', close the browser notification if displayed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new terminal with commands 'sudo' and 'la' performed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

