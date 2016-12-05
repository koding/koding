$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_open_terminal_refresh', ->
    describe "Switch the other browser window where you are logged in as 'rainforestqa99' and mouse over user icon at the left of 'END COLLABORATION' button then click on 'Make Presenter'?", ->
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

    describe "Click + icon in the editor area and click 'New Session' in the 'New Terminal' section of the menu (like on screenshot http://snag.gy/jJiod.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new terminal tab opened??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Remember the list of editors and terminals opened and return to the other browser window where you are logged in as 'rainforestqa99', close the browser notification if displayed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new terminal tab opened??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click refresh icon in the browser?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the same list of editors and terminals after refreshing??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Minimize the window of the browser and return to the incognito browser window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the same list of editors and terminals??", (done) -> 
        assert(false, 'Not Implemented')
        done()

