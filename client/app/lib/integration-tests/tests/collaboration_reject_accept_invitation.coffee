$ = require 'jquery'
assert = require 'assert'

#! fb135bfa-5679-478d-84b1-3173e8276ff6
# title: collaboration_reject_accept_invitation
# start_uri: /
# tags: automated
#

describe "collaboration_reject_accept_invitation.rfml", ->
  before -> 
    require './create_team_with_existing_user_stack_related.coffee'

  describe """Enter "rainforestqa22@koding.com" in the 'Email' field of the second row and click on 'SEND INVITES' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Invitation is sent to rainforestqa22@koding.com' message displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ sandbox.auth }}@{{ random.last_name }}{{ random.number }}.{{site.host}}' by pasting the url (using ctrl-v) in the address bar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22" both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button""", ->
    before -> 
      # implement before hook 

    it """Are you successfully logged in?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '_Aws Stack' label??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the 'NEXT' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Select Credentials' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see  AWS Keys label in a text box?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a BUILD STACK button and 'BACK TO INSTRUCTIONS' text on the bottom??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the BUILD STACK button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Fetching and validating credentials...' text in a progress bar??""", -> 
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

    it """Do you see '_Aws Stack' under 'STACKS' title in the left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a green square next to 'aws-instance' label?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '/home/rainforestqa22' label on top of a file list?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'cloud-init-o_' file on top and 'Terminal' tab on the bottom pane?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch the first browser and close that modal by clicking (x) from top right corner of the 'Invitations' pane""", ->
    before -> 
      # implement before hook 

    it """Is that pane closed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click  'START COLLABORATION' button in the bottom right corner""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Starting session' progress bar below the button and after that 'START COLLABORATION' button is converted to 'END COLLABORATION'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a shortened URL in the bottom status bar (like on screenshot http://snag.gy/dp1Cn.jpg )??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click shortened URL in the bottom status bar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Copied to clipboard!' popup message??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Remember the list of panes opened (terminal, untitled.txt, etc) and select the incognito window and paste copied URL in the browser address bar and press enter""", ->
    before -> 
      # implement before hook 

    it """Do you see 'SHARED VMS' label in the left module on the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'aws-instance' item below the 'SHARED VMS' label?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see white popup with 'Reject' and 'Accept' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click 'Reject' button""", ->
    before -> 
      # implement before hook 

    it """Are 'aws-instance' item removed from the left module and all panes from that VM closed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch the other browser window where you are logged in as 'rainforestqa99'""", ->
    before -> 
      # implement before hook 

    it """Do you see the only 'camera' icon at the left of 'END COLLABORATION' button without any other icons/avatars??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click 'END COLLABORATION' button and click 'Yes' on the 'Are you sure?' dialog""", ->
    before -> 
      # implement before hook 

    it """Is 'END COLLABORATION' button changed to 'START COLLABORATION'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is 'Camera' icon removed from the bottom status bar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click  'START COLLABORATION' button in the bottom right corner and click shortened URL in the bottom status bar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Copied to clipboard!' popup message??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the incognito browser window and paste copied URL in the browser address bar and press enter""", ->
    before -> 
      # implement before hook 

    it """Do you see 'SHARED VMS' label in the left module on the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'aws-instance' item below the 'SHARED VMS' label?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see white popup with 'Reject' and 'Accept' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click 'Accept' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Joining to collaboration session' progress bar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the same panes (terminal, untitled.txt) like on the browser where you are logged in as 'rainforestqa99'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """""", ->
    before -> 
      # implement before hook 


