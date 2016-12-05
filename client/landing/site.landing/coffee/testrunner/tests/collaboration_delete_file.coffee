$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_delete_file', ->
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

    describe "Close the warning and click  down arrow icon at the right of /home/rainforestqa99 label in the center part of the page, click 'New file' in the menu (like on screenshot http://snag.gy/nJ2Dd.jpg ) and enter 'file{{random.number}}.txt' file name and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see file 'file{{random.number}}.txt' with green icon in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click down arrow icon at the right of 'file{{random.number}}.txt' file in the file tree and click 'Delete' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Are you sure?' text and red 'Delete' button above the file name??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'DELETE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'file{{random.number}}.txt' file deleted from file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the other browser window where you are logged in as 'rainforestqa99', close the browser notification if displayed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the uploaded file under the filetree?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is 'file{{random.number}}.txt' file removed from file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

