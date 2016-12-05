$ = require 'jquery'
assert = require 'assert'
enable_VM_sharing_invite_Member = require './enable_VM_sharing_invite_Member'

module.exports = ->

  enable_VM_sharing_invite_Member()

  describe 'sharedVMs_createAndSaveNewFile_leaveSharedVM_seeFileAsVmOwner', ->
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

    describe "Click on the '+' next to 'Terminal' tab and select 'New File'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Untitled.txt' added to that pane??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Type '{{ random.full_name }}' in it, click on the little down arrow next to 'Untitled.txt' and select 'Save'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Filename:' title and a text field with 'Untitled.txt' in it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Select a folder:' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL' and 'SAVE' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Type '{{ random.first_name }}' instead of 'Untitled' and click on 'SAVE' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is '{{ random.first_name }}.txt' added to the pane instead of 'Untitled.txt'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is it also added to the end of file list under '/home/rainforestqa99'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Move your mouse over 'test(@rainforestqa99)' label on left sidebar under 'SHARED VMS' and click on the button appeared next to it?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Shared with you by' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '@rainforestqa99'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'LEAVE SHARED VM' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'LEAVE SHARED VM' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Are you sure?' titled pop-up?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'This will remove the shared VM from your sidebar.' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL' and 'YES' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'YES'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are 'SHARED VMS' and 'test(@rainforestqa99)' removed from left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Are you switched to '_Aws Stack?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that '/home/rainforestqa99' label and 'Terminal' tab are not displayed anymore??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser and close that modal by clicking (x) from top right corner?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '{{ random.first_name }}.txt' at the end of file list under '/home/rainforestqa99' next to left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click on the '{{ random.first_name }}.txt' file?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see it opened as a new tab?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '{{ random.full_name }}' in it??", (done) -> 
        assert(false, 'Not Implemented')
        done()

