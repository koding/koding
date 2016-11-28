$ = require 'jquery'
assert = require 'assert'

#! 3e012e10-a8d1-46ee-a0b2-1431bb2ec635
# title: disableUser_removePermanently
# start_uri: /
# tags: automated
#

describe "disableUser_removePermanently.rfml", ->
  before -> 
    require './create_team_with_existing_account.coffee'

  describe """Enter "rainforestqa22@koding.com" in 'Email' field that's highlighted, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)""", ->
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

    it """Do you see 'You are almost there, rainforestqa22!' title on a pop-up in the center of the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your Team Stack is Pending' text in that pop-up??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser, scroll down to 'Teammates' section""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Member' label and a little down arrow next to 'rainforestqa22'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Member' and select 'Disable user'""", ->
    before -> 
      # implement before hook 

    it """Is 'Member' label next to it updated as 'Disabled'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is it moved to the bottom of the list??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window""", ->
    before -> 
      # implement before hook 

    it """Do you see that you're logged out automatically?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """(If not, do you see 'Your access is revoked!' text?)?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22" both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button (If you see 'Your access is revoked!' text, delete '/Banned' from the address bar above and press enter, then do the actions above)""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'You are not allowed to access this team' warning displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser, click on 'Disabled' label and select 'Enable user'""", ->
    before -> 
      # implement before hook 

    it """Is 'Disabled' label next to it updated as 'Member' again??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window and click on 'SIGN IN' button""", ->
    before -> 
      # implement before hook 

    it """Are you successfully logged in??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser, click on 'Member' and select 'Disable user'""", ->
    before -> 
      # implement before hook 

    it """Is 'Member' label next to it updated as 'Disabled'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is it moved to the bottom of the list??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Disabled' label and select 'Remove Permanently'""", ->
    before -> 
      # implement before hook 

    it """Is 'rainforestqa22' removed from the list??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch to the incognito window""", ->
    before -> 
      # implement before hook 

    it """Do you see that you're logged out automatically?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """(If not, do you see 'Your access is revoked!' text?)?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22" both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button (If you see 'Your access is revoked!' text, delete '/Banned' from the address bar above and press enter, then do the actions above)""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'You are not allowed to access this team' warning displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


