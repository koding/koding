$ = require 'jquery'
assert = require 'assert'
enable_VM_sharing_invite_Member = require './enable_VM_sharing_invite_Member'

module.exports = ->

  enable_VM_sharing_invite_Member()

  describe 'sharedVMs_viewEditExistingFiles_saveAs_seeTheUpdatesAsVmOwner', ->
    describe "Switch back to first browser window. Click to down arrow next to '/home/rainforestqa99' label and then click to 'New file'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that 'NewFile.txt' added??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Type '{{random.first_name}}' and hit ENTER and then double click to it?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '{{random.first_name}}.txt' added to the file list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window, click on 'ACCEPT' button on the pop-up appeared?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '/home/rainforestqa99' label on top of a file list next to left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '{{ random.first_name }}.txt' in the file list under '/home/rainforestqa99' label?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Terminal' tab on the bottom?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'rainforestqa99@rainforestqa99:~$' in that 'Terminal' tab??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the area under 'Untitled.txt' on top, then double click on the '{{ random.first_name }}.txt' file?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that it's empty??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Type '{{ random.full_name }}' in it, click on the little down arrow next to '{{ random.first_name }}.txt' label above and then select 'Save'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen that the green dot next to '{{ random.first_name }}.txt' disappeared??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Type '{{ random.number }}' next to '{{ random.full_name }}' in the file, click on the little down arrow next to '{{ random.first_name }}.txt' label above and then select 'Save As...'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Filename:' title and a text field with '{{ random.first_name }}.txt' in it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Select a folder:' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL' and 'SAVE' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Clear text in filename input then type '{{ random.last_name }}.txt' and then click to 'SAVE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is '{{ random.last_name }}.txt' added to the pane next to '{{ random.first_name }}.txt'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is it also added to the end of file list under '/home/rainforestqa99'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch back to first browser window which you are logged in as user rainforestqa99?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that '{{ random.last_name }}.txt' is added to the end of file list under '/home/rainforestqa99'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'This file has changed on disk. Do you want to reload it?' text under '{{ random.first_name }}.txt'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you also see 'NO' and 'YES' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'YES' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '{{ random.full_name }}' in the file??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click on '{{ random.last_name }}.txt' from the file list?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is it opened next to '{{ random.first_name }}.txt'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '{{ random.full_name }}{{ random.number }}' in it??", (done) -> 
        assert(false, 'Not Implemented')
        done()

