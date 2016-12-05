$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_create_newfile_from_IDE', ->
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

    describe "Close the warning and click  down arrow icon at the right of /home/{{random.first_name}}{{random.number}} label in the center part of the page and click 'New file' in the menu (like on screenshot http://snag.gy/nJ2Dd.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new file 'NewFile.txt' added to the file tree?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is file name displayed in edit mode??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'file2.txt' file name and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see file 'file2.txt' with green icon in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click on the 'file2.txt' file?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new editor tab opened for this file??", (done) -> 
        assert(false, 'Not Implemented')
        done()

