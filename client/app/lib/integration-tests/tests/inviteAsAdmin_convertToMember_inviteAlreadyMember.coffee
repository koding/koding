$ = require 'jquery'
assert = require 'assert'

#! cf174fab-3e76-45c9-a614-5bfa938cabec
# title: inviteAsAdmin_convertToMember_inviteAlreadyMember
# start_uri: /
# tags: automated
#

describe "inviteAsAdmin_convertToMember_inviteAlreadyMember.rfml", ->
  before -> 
    require './create_team_with_existing_account.coffee'

  describe """Enter "rainforestqa22@koding.com" in the 'Email' field of the first row, "{{ random.email }}" in the second row and "rainforest+{{ random.email }}" in the third row""", ->
    before -> 
      # implement before hook 

    it """Do you see that 4th row is autoadded to the list??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'SEND INVITES' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'You're adding an admin' pop-up?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CANCEL' and 'THAT'S FINE' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'THAT'S FINE' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'All invitations are sent.' message displayed??""", -> 
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

    it """Do you see '{{ random.last_name }}{{ random.number }}' label at the top left corner?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'You are almost there, rainforestqa22!' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Create a Stack for Your Team', 'Enter your Credentials', 'Build Your Stack', 'Invite Your Team' and 'Install KD' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CREATE', 'ENTER', 'BUILD', 'INVITE' and 'INSTALL' links next to them??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Invite Your Team' section""", ->
    before -> 
      # implement before hook 

    it """Are you directed to 'Send Invites' section of 'My Team' tab?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Admin' checkbox field at the end of the row?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Team Billing' item under 'Dashboard' from left vertical menu??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser and scroll down to the bottom of the page""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Admin' label next to 'rainforestqa22'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a yellow star icon next to rainforestqa22's avatar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Scroll up to 'Send Invites' section again, enter "rainforestqa22@koding.com" in the first row and click on 'SEND INVITES' and then click on 'THAT'S FINE' button (be sure that admin checkbox is checked)""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Invites Already Sent' title on a pop-up appeared?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'rainforestqa22@koding.com is already a member of your team.' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'OK' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'OK' button and scroll down to the bottom of the page again and click on the little down arrow next to 'Admin' label""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Make owner', 'Make member' and 'Disable user' options?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the same little down arrow next to 'Owner' label??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Select 'Make member'""", ->
    before -> 
      # implement before hook 

    it """Is 'Admin' label next to 'rainforestqa22' updated as 'Member'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is the little down arrow next to 'Owner' label above is disappeared??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Your team role has been changed!' title on a pop-up appeared?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '@rainforestqa99 made you a member, please refresh your browser for changes to take effect.' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'RELOAD PAGE' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'RELOAD PAGE' button""", ->
    before -> 
      # implement before hook 

    it """Is 'Team Billing' item removed from left vertical menu?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is 'Admin' checkbox removed from 'Send Invites' section?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Are the little down arrows next to 'Owner', 'Invitation Sent' and 'Member' removed and no longer available (in Teammates section on the bottom of the page)?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Member' label next to 'rainforestqa22'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


