$ = require 'jquery'
assert = require 'assert'

#! 11f8451a-27cb-4270-8d58-3ca37ce66aa6
# title: send_resend_revoke_openRevoked_invitation
# start_uri: /
# tags: automated
#

describe "send_resend_revoke_openRevoked_invitation.rfml", ->
  before -> 
    require './create_team_with_existing_account.coffee'

  describe """Enter "rainforest+{{ random.first_name }}" email and click on 'SEND INVITES' button""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'That doesn't seem like a valid email address.' warning??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Delete the text from email field and enter "{{ random.email }}" in the 'Email', "{{ random.first_name }}{{ random.number }}" in the 'First Name' fields and enter "rainforestqa22@koding.com" email in the second row and click on 'SEND INVITES' button""", ->
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


  describe """Scroll down to the bottom of the page""", ->
    before -> 
      # implement before hook 

    it """Do you see 'rainforestqa99' and 'Owner' label next to it?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '{{ random.email }}' and 'rainforestqa22@koding.com' listed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Invitation Sent' text next to them?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a little down arrow next to 'Invitation Sent' labels??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the little down arrow next to '{{ random.email }}'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Resend Invitation' and 'Revoke Invitation' options??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Resend Invitation'""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Invitation is resent.' message displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the little down arrow next to '{{ random.email }}' again and then click on 'Revoke Invitation'""", ->
    before -> 
      # implement before hook 

    it """Is '{{ random.email }}' removed from the list??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ random.inbox }}' by pasting the url (using ctrl-v) in the address bar, wait ~1min and refresh the page""", ->
    before -> 
      # implement before hook 

    it """Do you see two 'You are invited to join a team on Koding' emails in inbox that received a few minutes ago?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """(Ignore older emails)?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Open Email' for the last one of 'You are invited to join a team on Koding' emails""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Hi there, You received this email because rainforestqa99 would like you to join {{ random.last_name }}{{ random.number }}'s Team on Koding.com' text in the email?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'ACCEPT INVITE' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'ACCEPT INVITE' button, then if you see 'Authentication Required' form opened in the new tab, enter "koding" in the 'User Name:' and "1q2w3e4r" in the 'Password:' fields and click on 'Log In' (if not do nothing and check the items below) """, ->
    before -> 
      # implement before hook 

    it """Have you seen 'invitation not found' message that disappears after a second?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text and 'SIGN IN' button??""", -> 
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

    it """Do you see 'You are almost there, rainforestqa22!' title in the center of the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your Team Stack is Pending' and 'PENDING' text next to it??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser (you can close the incognito window)""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Member' text next to 'rainforestqa22'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


