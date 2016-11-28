$ = require 'jquery'
assert = require 'assert'

#! 4691279c-8028-4275-b174-ac9192669997
# title: login_to_an_existing_team_with_alwaysON_VM
# start_uri: /
# tags: sandbox
#

describe "login_to_an_existing_team_with_alwaysOn_VM.rfml", ->
  describe """Enter "{{ always_on_existing_team.name }}" (in lowercase like in the 'rainforestqateam') in the input field 'your-team-name' and click on 'LOGIN' button and then if you see 'Authentication Required' form enter "koding" in the 'User Name:' and "1q2w3e4r" in the 'Password:' fields and click on 'Log In' (if not do nothing and check the items below)""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Sign in to {{ always_on_existing_team.name }}' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa99@koding.com" in the 'Your Username or Email' and "rainforestqa99" in the 'Your Password' fields and click on 'SIGN IN' button""", ->
    before -> 
      # implement before hook 

    it """Do you see '{{ always_on_existing_team.name }}' label at the top left corner?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'You are almost there, rainforestqa99!' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Create a Stack for Your Team', 'Enter your Credentials', 'Build Your Stack', 'Invite Your Team' and 'Install KD' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'CREATE', 'ENTER', 'BUILD', 'INVITE' and 'INSTALL' links next to them??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close that modal by clicking (x) from top right corner""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Team Stack' under 'STACKS' title in the left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a green square next to 'example_1' label?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '/home/rainforestqa99' label on top of a file list?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a 'Terminal' tab and mostly green text on it (something like this image here: http://take.ms/zAa0yp)??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


