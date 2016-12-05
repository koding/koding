$ = require 'jquery'
assert = require 'assert'
collaboration_start_session_invite_member = require './collaboration_start_session_invite_member'

module.exports = ->

  collaboration_start_session_invite_member()

  describe 'collaboration_upload_file', ->
    describe "Save image from here: {{ random.image }} to your desktop, return to the incognito browser window and drag and drop image to the Filetree under /home/{{random.first_name}}{{random.number}}  label (like in the screencast: http://recordit.co/KRArrgJ8Gs)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is it added to the end of Filetree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

