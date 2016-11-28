$ = require 'jquery'
assert = require 'assert'

#! c269cf05-c183-4c76-b831-0a22734ee2a4
# title: myteam_settings
# start_uri: /
# tags: automated
#

describe "myteam_settings.rfml", ->
  before -> 
    require './create_team_with_existing_account.coffee'

  describe """Enter "rainforestqa22@koding.com" in the 'Email' field of the second row (not the first row) and click on 'SEND INVITES' button""", ->
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

    it """Do you see '{{ random.last_name }}{{ random.number }}' label at the top left corner?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'You are almost there, rainforestqa22!' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your Team Stack is Pending' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'PENDING' text next to it??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click team name on the left side bar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Member' in the opening menu?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser and scroll up to the top of the page""", ->
    before -> 
      # implement before hook 

    it """Do you see the team name field has correct value "{{ random.last_name }}{{ random.number }}" and url includes correct team name "{{ random.last_name }}{{ random.number }}" ??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter new random team name in 'Team Name' field and click on 'CHANGE TEAM NAME' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Team settings has been successfully updated.' message displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window then click on team name on the top left, click on 'Dashboard' in the opening menu and then click on 'My Team'""", ->
    before -> 
      # implement before hook 

    it """Is 'Team Name' not editable ?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is 'CHANGE TEAM NAME' button not visible??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to first browser save image from here: {{ random.image }} to your desktop, click on 'UPLOAD LOGO' and choose the picture""", ->
    before -> 
      # implement before hook 

    it """Is 'Team settings has been successfully updated' message displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the uploaded logo??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'REMOVE LOGO'""", ->
    before -> 
      # implement before hook 

    it """Is 'Team settings has been successfully updated' message displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is logo removed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window then click on 'LEAVE TEAM'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Please verify your current password', 'FORGOT PASSWORD', 'CONFIRM' buttons ??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22" then click on 'CONFIRM'""", ->
    before -> 
      # implement before hook 

    it """Are you logged out?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see random team name that you assigned on the login form??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22" both in the 'Username or Email' and 'Password' fields and click on 'SIGN IN' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'You are not allowed to access this team' message??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """""", ->
    before -> 
      # implement before hook 

