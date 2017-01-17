$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_readonly', ->
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

    describe "Click Terminal tab and try to enter any command in the terminal?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you unable to enter commands in the terminal??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Try click '+' icon at the right of terminal and select New Terminal -> New Session ( http://snag.gy/UnOoo.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you unable to click this button or button is unavailable??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over 'aws-instance' item below the 'SHARED VMS' label and click '...' icon displayed (like on screenshot http://snag.gy/RhBjF.jpg)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see popup with red 'LEAVE SESSION' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

