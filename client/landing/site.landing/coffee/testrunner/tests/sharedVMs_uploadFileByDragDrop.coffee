$ = require 'jquery'
assert = require 'assert'
enable_VM_sharing_invite_Member = require './enable_VM_sharing_invite_Member'

module.exports = ->

  enable_VM_sharing_invite_Member()

  describe 'sharedVMs_uploadFileByDragDrop', ->
    describe "Click on 'ACCEPT' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '/home/rainforestqa99' label on top of a file list next to left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Terminal' tab on the bottom?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'rainforestqa99@rainforestqa99:~$' in that 'Terminal' tab??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Save image from here: {{ random.image }} to your desktop, return to the incognito window and drag and drop image to the file list under '/home/rainforestqa99' label (like in the screencast: http://recordit.co/KRArrgJ8Gs)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is it added to the end of file list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the area under 'Untitled.txt' on top, then double click on the '.profile' file from file list under '/home/rainforestqa99' label and reload the page?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see still see '.profile' on top and 'Terminal' on the bottom??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser and close the modal by clicking (x) from top right corner?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that the image you newly added (by drag&drop) is listed under the file list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

