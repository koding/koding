$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_create_save_files', ->
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

    describe "Close the warning and click 'Untitled.txt' file at the editor area and type '{{random.address_city}}' in the first row?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see text entered??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over 'Untitled.txt', click down arrow icon displayed ans click Save in menu (like on screenshot http://snag.gy/zNMRr.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new modal with 'Filename', 'Select a folder' fields and 'Save' and 'Cancel' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'file1.txt' in the 'Filename' field and click 'Save'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is modal closed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the 'file1.txt' title of the opened file instead of 'Untitled.txt'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the file 'file1.txt' in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

