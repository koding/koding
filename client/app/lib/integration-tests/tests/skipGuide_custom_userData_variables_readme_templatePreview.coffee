$ = require 'jquery'
assert = require 'assert'

#! 5f8145f5-e038-4144-90ad-82e793934a6c
# title: skipGuide_custom_userData_variables_readme_templatePreview
# start_uri: /
# tags: automated
#

describe "skipGuide_custom_userData_variables_readme_templatePreview.rfml", ->
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


  describe """Click on 'Credentials' text having a red (!) next to it""", ->
    before ->
      # implement before hook

    it """Do you see 'rainforestqa99's AWS keys'?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'USE THIS & CONTINUE' button next to it?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'ADD A NEW CREDENTIAL' button on the bottom??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Move your mouse over 'USE THIS & CONTINUE' button""", ->
    before ->
      # implement before hook

    it """Have 'PREVIEW' and 'DELETE' texts appeared??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'PREVIEW'""", ->
    before ->
      # implement before hook

    it """Do you see 'rainforestqa99's AWS keys Preview' title on a pop-up displayed?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'access_key', 'region', 'secret_key' and 'identifier' sections?""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close that modal by clicking (x) from top right corner and click on 'USE THIS & CONTINUE' button (next to 'rainforestqa99's AWS keys') and wait for a second for process to be completed""", ->
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


  describe """Click on 'Edit Name' link """, ->
    before ->
      # implement before hook

    it """Is '_Aws Stack' converted to a textbox??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Delete the text and write "Team Stack" instead of it and hit enter""", ->
    before ->
      # implement before hook

    it """Is it updated successfully as 'Team Stack' also on left sidebar under 'STACKS' section??""", ->
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

    it """Do you see '# You can define your custom variables' text in the first line?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Have you seen that the red warning has disappeared??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Readme' tab""", ->
    before ->
      # implement before hook

    it """Do you see '###### Stack Template Readme' text in the first line?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'PREVIEW' button on the bottom right??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Delete the text and copy and paste "# WELCOME TO KODING! You've said goodbye to your localhost and are ready to develop software in the cloud!" there and click on 'PREVIEW' button""", ->
    before ->
      # implement before hook

    it """Do you see 'Readme Preview' title on a pop-up displayed?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the text you pasted??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close that modal by clicking (x) from top right corner, switch to 'Stack Template' tab and click on 'PREVIEW' button on the right bottom""", ->
    before ->
      # implement before hook

    it """# Do you see 'Template Preview' title on a pop-up displayed??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on EXPAND""", ->
    before ->
      # implement before hook

    it """Has that pop-up expanded?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'COLLAPSE' button on top right??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'COLLAPSE', close the 'Template Preview' by clicking (x) from top right (if you cannot see (x) then press ESC) and then click on 'SAVE' button on top right and wait for a few seconds for that process to be completed""", ->
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


  describe """Click on 'CANCEL'""", ->
    before ->
      # implement before hook

    it """Do you see 'MAKE TEAM DEFAULT', 'INITIALIZE' and 'SAVE' buttons on top right??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'INITIALIZE' button and wait for a few seconds for process to be completed""", ->
    before ->
      # implement before hook

    it """Do you see 'Team Stack' title?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Read Me' and 'WELCOME TO KODING' texts?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', 'Team Stack' and 'aws-instance' labels on left sidebar??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'NEXT' button""", ->
    before ->
      # implement before hook

    it """Do you see 'Select Credentials and Other Requirements' text?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'rainforestqa99's AWS keys' label in the text box on the left-side?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Requirements:' title, 'Requirement Selection' text and a text box on the right-side?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '+ Create New' link below??""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on '+ Create New' under Requirements (if you don't see '+ Create New under requirements section just enter the following values under 'New Requirements:' section on the right-side), enter "{{ random.first_name }}_build" in 'Title', "{{ random.first_name }}" in 'Name' fields and click on BUILD STACK button""", ->
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


  describe """Click on START CODING button""", ->
    before ->
      # implement before hook

    it """Do you see 'Team Stack' under 'STACKS' title in the left sidebar?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a green square next to 'aws-instance' label?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '/home/rainforestqa99' label on top of a file list?""", ->
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'cloud-init-o_' file on top and 'Terminal' tab on the bottom pane?""", ->
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the tab where it says 'Terminal', type "ls /" and hit enter""", ->
    before ->
      # implement before hook

    it """Do you see the green colored 'helloworld.txt', 'qa_test' and '{{ random.first_name }}' files in the list??""", ->
      assert(false, 'Not Implemented')
      #assertion here


