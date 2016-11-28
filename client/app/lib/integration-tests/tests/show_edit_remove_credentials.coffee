$ = require 'jquery'
assert = require 'assert'

#! 53c55879-0372-4da6-86c3-a07ee8bab35d
# title: show_edit_remove_credentials
# start_uri: /
# tags: automated
#

describe "show_edit_remove_credentials.rfml", ->
  before ->
    require './create_team_with_existing_account.coffee'

  describe """Click on 'amazon web services' and then click on 'CREATE STACK' button""", ->
    before ->
      # implement before hook

    it """Has that pop-up disappeared?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '_Aws Stack' title?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Stack Template', 'Custom Variables', 'Readme' tabs?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Credentials' text having a red (!) next to it?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '# Here is your stack preview' in the first line of main content?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'PREVIEW', 'LOGS', 'DELETE THIS STACK TEMPLATE' buttons on the bottom and 'SAVE' button on top right??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Credentials' and then click on 'ADD A NEW CREDENTIAL' button on the bottom""", ->
    before ->
      # implement before hook

    it """Do you see 'Add your AWS credentials' title?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Title', 'Access Key ID' , 'Secret Access Key' and 'Region' fields?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL', 'ADVANCED MODE' and 'SAVE' buttons??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "{{ random.first_name }}" in 'Title', "{{ random.number }}" in 'Access Key ID', "{{ random.password }}" in 'Secret Access Key' fields and click on 'SAVE' button below""", ->
    before ->
      # implement before hook

    it """Is it added to the list above 'rainforestqa99's AWS keys'??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'ADD A NEW CREDENTIAL' button again, enter "{{ random.last_name }}" in 'Title', "{{ random.number }}" in 'Access Key ID', "{{ random.password }}" in 'Secret Access Key' fields and click on 'SAVE' button below""", ->
    before ->
      # implement before hook

    it """Is it added to the list??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Move your mouse over '{{ random.last_name }}' text, click on 'DELETE' link appeared and then click on 'REMOVE CREDENTIAL' button""", ->
    before ->
      # implement before hook

    it """Is it removed from the list successfully??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'USE THIS & CONTINUE' button next to 'rainforestqa99's AWS keys' and wait for a second for process to be completed""", ->
    before ->
      # implement before hook

    it """Have you seen 'Verifying Credentials...' message displayed?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Are you switched to 'Stack Template' tab?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """(If you're not switched and you got 'Failed to verify: operation timed out' error, click on the same button again)?""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe '''Click end of the line next to the last word on line 23, hit enter (by doing this you should go to the next line) and type "touch /${var.custom_key}", hit enter again and then type "touch /${var.userInput_name}"''', ->
    before ->
      # implement before hook

    it """Do you see that (1) as a red warning appeared next to 'Custom Variables' tab??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Custom Variables' tab and type " key: 'qa_test' " at the end of the file (like in the screenshot here: http://take.ms/DZb5a)""", ->
    before ->
      # implement before hook

    it """Have you seen that the red warning has disappeared?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '# You can define your custom variables' text in the first line??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'SAVE' button on top right and wait for a few seconds for that process to be completed""", ->
    before ->
      # implement before hook

    it """Do you see 'Share Your Stack_' title on a pop-up displayed?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that 'Share the credentials I used for this stack with my team.' checkbox is already checked?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL' and 'SHARE WITH THE TEAM' buttons??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'CANCEL' and 'INITIALIZE' buttons respectively and wait for a few seconds for process to be completed""", ->
    before ->
      # implement before hook

    it """Do you see '_Aws Stack' title?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Read Me' text?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'NEXT' button""", ->
    before ->
      # implement before hook

    it """Do you see 'Select Credentials and Other Requirements' text?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'rainforestqa99's AWS keys' label in the text box on the left side?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'New Requirements:' title and a 'Name' text box  on the right-side?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '+ Create New' link below of 'AWS Credential:' section on the left side??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on '+ Create New' under 'Requirements:' section, enter "{{ random.first_name }}_build" in 'Title', "{{ random.first_name }}" in 'Name' fields and click on BUILD STACK button""", ->
    before ->
      # implement before hook

    it """Do you see 'Fetching and validating credentials...' text in a progress bar?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a green progress bar also below 'aws-instance' label on left sidebar??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Wait for a few minutes for process to be completed""", ->
    before ->
      # implement before hook

    it """Do you see 'Success! Your stack has been built.' text?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'View The Logs', 'Connect your Local Machine' and 'Invite to Collaborate' sections?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see START CODING button on the bottom??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Move your mouse over 'aws-instance' label on left sidebar and click on the circle button appeared next to it""", ->
    before ->
      # implement before hook

    it """Has a pop-up appeared?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Stacks', 'Virtual Machines' and 'Credentials' tabs on top?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'aws-inst_' under 'Virtual Machines' section?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Edit VM Name', 'VM Power', 'Always On', 'VM Sharing' and 'Build Logs' sections under it??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Credentials' tab""", ->
    before ->
      # implement before hook

    it """Do you see 'rainforestqa99's AWS keys' and '{{ random.first_name }}'and 'AWS' labels next to them?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Custom Variables for _Aws St_' and 'CUSTOM' label next to it?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '{{ random.first_name }}_build' and 'USERINPUT' label next to it?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see only 'SHOW' and 'REMOVE' links next to 'AWS' labeled items?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you also see 'EDIT' next to other items??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'SHOW' next to 'rainforestqa99's AWS keys'""", ->
    before ->
      # implement before hook

    it """Do you see a 'rainforestqa99's AWS keys Preview' titled pop-up?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see "access_key", "acl", "ami" and other fields listed??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close that pop-up by clicking (x) from top right corner and click on 'EDIT' next to '{{ random.first_name }}_build'""", ->
    before ->
      # implement before hook

    it """Do you see 'Edit Credential' titled pop-up?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Title' and 'Name' titled text boxes?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL' and 'SAVE' buttons??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'Name' text box, delete '{{ random.first_name }}', type "test", and click on 'SAVE' button, then click on 'SHOW' link next to it""", ->
    before ->
      # implement before hook

    it """Do you see '{{ random.first_name }}_build Preview' titled pop-up?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see "name": "test",??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close that pop-up by clicking (x) from top right corner, click on 'REMOVE' next to '{{ random.first_name }}' and then click on 'REMOVE CREDENTIAL' button""", ->
    before ->
      # implement before hook

    it """Is it removed successfully from the list??""", ->
      assert(false, 'Not Implemented')
      #assertion here


