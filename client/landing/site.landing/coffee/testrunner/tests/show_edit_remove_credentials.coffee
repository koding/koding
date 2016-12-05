$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_account = require './create_team_with_existing_account'

module.exports = ->

  create_team_with_existing_account()

  describe 'show_edit_remove_credentials', ->
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

    describe "Click on 'Credentials' and then click on 'ADD A NEW CREDENTIAL' button on the bottom?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Add your AWS credentials' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Title', 'Access Key ID' , 'Secret Access Key' and 'Region' fields?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL', 'ADVANCED MODE' and 'SAVE' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '{{ random.first_name }}' in 'Title', '{{ random.number }}' in 'Access Key ID', '{{ random.password }}' in 'Secret Access Key' fields and click on 'SAVE' button below?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is it added to the list above 'rainforestqa99's AWS keys'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'ADD A NEW CREDENTIAL' button again, enter '{{ random.last_name }}' in 'Title', '{{ random.number }}' in 'Access Key ID', '{{ random.password }}' in 'Secret Access Key' fields and click on 'SAVE' button below?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is it added to the list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Move your mouse over '{{ random.last_name }}' text, click on 'DELETE' link appeared and then click on 'REMOVE CREDENTIAL' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is it removed from the list successfully??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'USE THIS & CONTINUE' button next to 'rainforestqa99's AWS keys' and wait for a second for process to be completed?", ->
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

    describe "Click end of the line next to the last word on line 23, hit enter (by doing this you should go to the next line) and type 'touch /${var.custom_key}', hit enter again and then type 'touch /${var.userInput_name}'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see that (1) as a red warning appeared next to 'Custom Variables' tab??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Custom Variables' tab and type ' key: 'qa_test' ' at the end of the file (like in the screenshot here: http://take.ms/DZb5a)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Have you seen that the red warning has disappeared?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '# You can define your custom variables' text in the first line??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'SAVE' button on top right and wait for a few seconds for that process to be completed?", ->
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

    describe "Click on 'CANCEL' and 'INITIALIZE' buttons respectively and wait for a few seconds for process to be completed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '_Aws Stack' title?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Read Me' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the 'NEXT' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Select Credentials and Other Requirements' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'rainforestqa99's AWS keys' label in the text box on the left side?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'New Requirements:' title and a 'Name' text box  on the right-side?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '+ Create New' link below of 'AWS Credential:' section on the left side??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on '+ Create New' under 'Requirements:' section, enter '{{ random.first_name }}_build' in 'Title', '{{ random.first_name }}' in 'Name' fields and click on BUILD STACK button?", ->
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

    describe "Move your mouse over 'aws-instance' label on left sidebar and click on the circle button appeared next to it?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Has a pop-up appeared?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Stacks', 'Virtual Machines' and 'Credentials' tabs on top?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'aws-inst_' under 'Virtual Machines' section?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Edit VM Name', 'VM Power', 'Always On', 'VM Sharing' and 'Build Logs' sections under it??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Credentials' tab?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'rainforestqa99's AWS keys' and '{{ random.first_name }}'and 'AWS' labels next to them?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Custom Variables for _Aws St_' and 'CUSTOM' label next to it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see '{{ random.first_name }}_build' and 'USERINPUT' label next to it?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see only 'SHOW' and 'REMOVE' links next to 'AWS' labeled items?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you also see 'EDIT' next to other items??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'SHOW' next to 'rainforestqa99's AWS keys'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a 'rainforestqa99's AWS keys Preview' titled pop-up?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'access_key', 'acl', 'ami' and other fields listed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close that pop-up by clicking (x) from top right corner and click on 'EDIT' next to '{{ random.first_name }}_build'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Edit Credential' titled pop-up?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Title' and 'Name' titled text boxes?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'CANCEL' and 'SAVE' buttons??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the 'Name' text box, delete '{{ random.first_name }}', type 'test', and click on 'SAVE' button, then click on 'SHOW' link next to it?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see '{{ random.first_name }}_build Preview' titled pop-up?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'name': 'test',??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close that pop-up by clicking (x) from top right corner, click on 'REMOVE' next to '{{ random.first_name }}' and then click on 'REMOVE CREDENTIAL' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is it removed successfully from the list??", (done) -> 
        assert(false, 'Not Implemented')
        done()

