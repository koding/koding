$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_saveas_check_marker', ->
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

    describe "Close the warning and click 'Untitled.txt' file at the editor area and type 'first row' in the first row, press Enter and type 'second row' in the second row?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see text entered??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over 'Untitled.txt' and click down arrow icon displayed and click 'Save as' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see menu expanded with 'Save', 'Save as' and other options?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a new modal with 'Filename', 'Select a folder' fields and 'Save' and 'Cancel' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'newfile{{random.number}}.txt' in the 'Filename' field and click 'Save'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is modal closed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'newfile{{random.number}}.txt' title of the opened file instead of 'Untitled.txt'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Set cursor and the end of 'second row' in the editor on the page, press enter and enter 'third row' text?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new row added?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a dot displayed at the left of 'newfile{{random.number}}.txt' title in the header??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the other browser window where you are logged in as 'rainforestqa99', close the browser notification if displayed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'newfile{{random.number}}.txt' file opened in the editor on the page?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a dot displayed at the left of 'newfile{{random.number}}.txt' title in the header?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the user name marker displayed at the right of 'third row' on the page?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'newfile{{random.number}}.txt' file in the list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

