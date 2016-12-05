$ = require 'jquery'
assert = require 'assert'
enable_VM_sharing_invite_Member = require './enable_VM_sharing_invite_Member'

module.exports = ->

  enable_VM_sharing_invite_Member()

  describe 'sharedVMs_reject_inviteAgain_accept_checkTerminalActions', ->
    describe "Click to 'REJECT' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did popup disappear?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Did 'test_' label disappear along with 'Shared VMs' section in sidebar on the left??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch back to first window and move your mouse over 'test' label on left sidebar and click on the circle button appeared next to it. Scroll down until you see 'VM Sharing'. Click on the toggle button next to 'VM Sharing'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is the label updated as 'OFF'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is it turned to gray??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click to toggle button next to 'VM Sharing' and then enter 'rainforestqa22' in the text box again, hit enter and wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'rainforestqa22' added below 'Type a username' text box?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is 'This VM has not yet been shared with anyone.' text removed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Switch to the incognito window and click on 'ACCEPT' button this time?", ->
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

    describe "Click on the tab where it says 'Terminal', type 'expr 5 + 5' and hit enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '10' as a result??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the '+' next to 'Terminal' tab?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'New File', 'New Terminal', 'New Drawing Board', 'Split Vertically', 'Split Horizontally' and 'Enter Fullscreen' options??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Move your mouse over 'New Terminal' and select 'New Session'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is a new 'Terminal' tab opened?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'rainforestqa99@rainforestqa99:~$' in it??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Type 'expr 5 + 5' and hit enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '10' as a result??", (done) -> 
        assert(false, 'Not Implemented')
        done()

