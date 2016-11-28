$ = require 'jquery'
assert = require 'assert'

#! e377fa4a-39bb-4082-988b-1e879b1ad4eb
# title: inviteAlreadyInvited_tryToLeaveTeamAsOnlyAdmin_MakeAdmin
# start_uri: /
# tags: automated
#

describe "inviteAlreadyInvited_tryToLeaveTeamAsOnlyAdmin_MakeAdmin.rfml", ->
  before -> 
    require './create_team_with_existing_account.coffee'

  describe """Enter "rainforestqa22@koding.com" in 'Email' field that's highlighted, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Invitation is sent to rainforestqa22@koding.com' message displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22@koding.com" in 'Email' field again and then click on 'SEND INVITES' below """, ->
    before -> 
      # implement before hook 

    it """Do you see 'Resend Invitation' titled pop-up displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'rainforestqa22@koding.com has already been invited.' text and 'CANCEL' and 'RESEND' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'RESEND' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Invitation is resent to rainforestqa22@koding.com' message displayed??""", -> 
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

    it """Do you see 'You are almost there, rainforestqa22!' title on a pop-up in the center of the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your Team Stack is Pending' text in that pop-up??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser, scroll up to 'Team Settings' section""", ->
    before -> 
      # implement before hook 

    it """Do you see 'LEAVE TEAM' link on the bottom of that section??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'LEAVE TEAM'""", ->
    before -> 
      # implement before hook 

    it """Do you see a pop-up displayed with 'Please verify your current password' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a text field with 'Current Password' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'FORGOT PASSWORD?' and 'CONFIRM' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa99" in the text field and click on 'CONFIRM' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'As owner of this group, you must first transfer ownership to someone else!' warning displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Scroll down to 'Teammates' section""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Member' label and a little down arrow next to 'rainforestqa22'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Member' and select 'Make admin'""", ->
    before -> 
      # implement before hook 

    it """Do you see that 'Member' label is updated as 'Admin'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see that a yellow star icon is added next to 'rainforestqa22'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Your team role has been changed!' title on a pop-up displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '@rainforestqa99 made you an admin,_' text  and 'RELOAD PAGE' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'RELOAD PAGE' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Create a Stack for Your Team', 'Enter your Credentials', 'Build Your Stack', 'Invite Your Team' and 'Install KD' sections on the pop-up displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CREATE', 'ENTER', 'BUILD', 'INVITE' and 'INSTALL' links next to them??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close that modal by clicking (x) from top right corner and click on 'STACKS' title from left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Create New Stack Template' text and 'NEW STACK' button next to it?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Team Billing' item in the left vertical menu under 'Dashboard' title??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


