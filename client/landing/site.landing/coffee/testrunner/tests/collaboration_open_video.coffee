$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_open_video', ->
    describe "Click on 'camera' icon at the left of 'END COLLABORATION'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is new tab opened included 'https://appear.in_' url?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see yourself in the video??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the other browser window where you are logged in as 'rainforestqa99' and Click on 'camera' icon at the left of 'END COLLABORATION'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is new tab opened with 'https://appear.in/koding_' url in the address bar above?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see both users on the screen?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'LEAVE' button top of the video??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the incognito browser window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see both users on the screen?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'LEAVE' button top of the video??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'LEAVE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Thank you for using appear.in' text??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close the tab?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see opened id?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'LEAVE SESSION' on status bar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the other browser window where you are logged in as 'rainforestqa99' and Click on 'LEAVE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Thank you for using appear.in' text??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close the tab?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see opened id?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'END COLLABORATION' on status bar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

