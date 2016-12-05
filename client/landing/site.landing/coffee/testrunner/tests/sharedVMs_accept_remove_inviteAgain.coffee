$ = require 'jquery'
assert = require 'assert'
enable_VM_sharing_invite_Member = require './enable_VM_sharing_invite_Member'

module.exports = ->

  enable_VM_sharing_invite_Member()

  describe 'sharedVMs_accept_remove_inviteAgain', ->
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

    describe "Click on 'STACKS' title from left sidebar and switch to 'Virtual Machines' tab on top of the pop-up displayed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'test' under 'Shared Machines' section?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'SHARED MACHINE' label next to it??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close that pop-up by clicking (x) from top right corner, return to the first browser and move your mouse over 'rainforestqa22'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a red (x) appeared next to it??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on (x) that has appeared?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'rainforestqa22' removed from the list?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'This VM has not yet been shared with anyone.' text??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a pop-up with 'Machine access revoked' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Your access to this machine has been removed by its owner.' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'OK' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'OK'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you swithced to '_Aws Stack'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that 'test' is removed from left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that '/home/rainforestqa99' label and 'Terminal' tab are not displayed anymore??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Return to the first browser, enter 'rainforestqa22' in the text box, hit enter and wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'rainforestqa22' added below 'Type a username' text box?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is 'This VM has not yet been shared with anyone.' text removed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'test(@rainforestqa99)' below 'SHARED VMS' title on left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a pop-up appeared next to it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'wants to share their VM with you.' text in that pop-up?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you also see 'REJECT' and 'ACCEPT' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

