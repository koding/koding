$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_account = require './create_team_with_existing_account'

module.exports = ->

  create_team_with_existing_account()

  describe 'reinitializeStackAfterChangingContent_seeTheBuildLogs', ->
    describe "Click on 'Create a Stack for Your Team' section?", ->
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


      it "Do you see 'Share Your Stack_' title on a pop-up displayed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that 'Share the credentials I used for this stack with my team.' checkbox is already checked?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL' and 'SHARE WITH THE TEAM' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'CANCEL' and 'INITIALIZE' buttons respectively and wait for a while for process to be completed?", ->
      before (done) -> 
        # implement before hook 
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

      it "Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the 'NEXT' button and then click on the 'BUILD STACK'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Fetching and validating credentials...' text in a progress bar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a green progress bar also below 'aws-instance' label on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Wait for a few minutes for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Success! Your stack has been built.' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'View The Logs', 'Connect your Local Machine' and 'Invite to Collaborate' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see START CODING button on the bottom??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on START CODING button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '_Aws Stack' under 'STACKS' title in the left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a green square next to 'aws-instance' label?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '/home/rainforestqa99' label on top of a file list?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'cloud-init-o_' file on top and 'Terminal' tab on the bottom pane??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the tab where it says 'Terminal', type 'ls /' and hit enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the green colored 'helloworld.txt' file in the list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the little down arrow next to '/home/rainforestqa99' label on top of file list next to left sidebar?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Refresh', 'Collapse', 'Change top folder', 'New file', 'New folder' and 'Toggle invisible files' options??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'New file'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'NewFile.txt' added to the end of the file list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Delete 'NewFile', enter '{{ random.first_name }}' and hit enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is the new file saved as '{{ random.first_name }}.txt'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the tab where it says 'Terminal' again, then type 'ls' and hit enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the green colored '{{ random.first_name }}.txt' file only??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the little down arrow next to '_Aws Stack' from left sidebar, then click on 'Reinitialize' and 'PROCEED' respectively?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen 'Reinitializing stack...' and 'Stack reinitalized' messages displayed respectively?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '_Aws Stack' title on the modal in the center of the page??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the 'NEXT' button and then click on the 'BUILD STACK'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Fetching and validating credentials...' text in a progress bar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a green progress bar also below 'aws-instance' label on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Wait for a few minutes for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Success! Your stack has been built.' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'View The Logs', 'Connect your Local Machine' and 'Invite to Collaborate' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see START CODING button on the bottom??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'View the Logs' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is that success modal closed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see something like in this image: http://take.ms/S2PPR?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '_Aws Stack' under 'STACKS' title in the left sidebar?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a green square next to 'aws-instance' label?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '/home/rainforestqa99' label on top of a file list?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'cloud-init-o_' file on top and 'Terminal' tab on the bottom pane?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see that '{{ random.first_name }}.txt' is not listed in the file list anymore??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the tab where it says 'Terminal', type 'ls' and hit enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that nothing is returned as a result and just 'rainforestqa99@rainforestqa99:~$_' is displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

