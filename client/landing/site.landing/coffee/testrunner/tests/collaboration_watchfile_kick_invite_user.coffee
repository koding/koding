$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_watchfile_kick_invite_user', ->
    describe "Try to click settings icon at the top of the filetree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you unable to click settings icon?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the orange warning 'WARNING: You don't have permission to make changes. Ask for permission.'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the other browser window where you are logged in as 'rainforestqa99', click 'Untitled.txt' file at the editor area and type '{{random.address_city}}' in the first row, Mouse over 'Untitled.txt', click down arrow icon displayed and click Save in menu (like on screenshot http://snag.gy/zNMRr.jpg )?", ->
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

    describe "Return to the incognito browser window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the 'file1.txt' file in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch back to the first window and move your mouse over default avatar icon next to 'END COLLABORATION' button (like on the screenshot http://snag.gy/UWgYw.jpg ),click on 'Kick' in the menu. Wait for a couple of seconds and then click on 'END COLLABORATION' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is user icon removed from the bottom navigation bar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the incognito browser window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Has 'Session End' dialog not displayed (it shouldn't be displayed)?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is 'LEAVE SESSION' button not visible anymore?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Your session has been closed' titled pop-up??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the other browser window, click  'START COLLABORATION' button in the bottom right corner and click on the shortened URL in the bottom status bar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Copied to clipboard!' popup message??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the incognito browser window and paste copied URL in the browser address bar and press enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'SHARED VMS' label in the left module on the page?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'aws-instance_' item below the 'SHARED VMS' label?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see white popup with 'Reject' and 'Accept' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'Accept' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Joining to collaboration session' progress bar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see the same panes (terminal, untitled.txt) like on the browser where you are logged in as 'rainforestqa99'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

