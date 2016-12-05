$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_user_stack_related = require './create_team_with_existing_user_stack_related'

module.exports = ->

  create_team_with_existing_user_stack_related()

  describe 'ide_switch_vms', ->
    describe "Open filetree menu ( http://snag.gy/Rmoax.jpg ) and click 'New file' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new file 'NewFile.txt' added to the file tree?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is file name displayed in edit mode??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'testfile{{random.number}}.txt' file name and press enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see file 'testfile{{random.number}}.txt' with a paper icon next to it in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over 'STACKS' and click '+' icon?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Select a Provider' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'amazon web services', 'VAGRANT', 'Google Cloud Platform', 'DigitalOcean', 'Azure', 'Marathon' and 'Softlayer'?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL' and 'CREATE STACK' buttons below??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'amazon web services' and then click on 'CREATE STACK' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Has that pop-up disappeared?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '_Aws Stack' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Custom Variables', 'Readme' tabs?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Credentials' text having a red (!) next to it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '# Here is your stack preview' in the first line of main content?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'DELETE THIS STACK TEMPLATE', 'PREVIEW' and 'LOGS' buttons on the bottom and 'SAVE' button on top right??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Credentials' and then click on 'USE THIS & CONTINUE' button next to 'rainforestqa99's AWS keys' and wait for a second for process to be completed (scroll down if you cannot see 'rainforestqa99's AWS keys')?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Verifying Credentials...' message displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Are you switched back to the first tab('_Aws Stack')?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "(If you're not switched and you got 'Failed to verify: operation timed out' error, click on the same button again)?", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the 'SAVE' button on top right and wait for a few seconds for that process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'MAKE TEAM DEFAULT', 'INITIALIZE' and 'SAVE' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'INITIALIZE' button and wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is that page closed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '_Aws Stack' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'STACKS', '_Aws Stack' and 'aws-instance-1' labels on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the 'NEXT' button and then click on the BUILD STACK button below and wait for a few minutes for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Success! Your stack has been built.' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'View The Logs', 'Connect Your Local Machine' and 'Invite to Collaborate' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see START CODING button on the bottom?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '_Aws Stack' under 'STACKS' title in the left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a green square next to 'aws-instance-1' label??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'aws-instance' labels on the left?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see file 'testfile{{random.number}}.txt' with a note icon in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'aws-instance-1' labels on the left?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'testfile{{random.number}}.txt' file not visible at the left in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

