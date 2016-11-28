$ = require 'jquery'
assert = require 'assert'

#! dee7ba4a-6aef-486c-bbbe-de7617c7374a
# title: collaboration_logout_login_in1minute
# start_uri: /
# tags: automated
#

describe "collaboration_logout_login_in1minute.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

  describe """Click on 'Logout'""", ->
    before -> 
      # implement before hook 

    it """Did you logout??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22" both in the 'Username or Email' and 'Password' fields and click on 'SIGN IN' button (You have to login again less than 1 minute)""", ->
    before -> 
      # implement before hook 

    it """Are you successfully logged in??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click to 'aws-instance_' under 'Shared VMs' section in sidebar on the left side and wait until it loads""", ->
    before -> 
      # implement before hook 

    it """Do you see 'LEAVE SESSION' at the bottom right corner of the window??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the other browser window where you are logged in as 'rainforestqa99', click on team name on the top left sidebar""", ->
    before -> 
      # implement before hook 

    it """Do you see with opening menu with 'Logout' item??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Logout'""", ->
    before -> 
      # implement before hook 

    it """Did you logout??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa99" both in the 'Username or Email' and 'Password' fields and click on 'SIGN IN' button (You have to login less than 1 minute)""", ->
    before -> 
      # implement before hook 

    it """Are you successfully logged in??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click to 'aws-instance' in 'Stacks' section and wait for it to load""", ->
    before -> 
      # implement before hook 

    it """If you see a modal then close it by clicking (x) at top right corner and wait for loading. Do you see 'END COLLABORATION' button at the bottom right corner??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


