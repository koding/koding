$ = require 'jquery'
assert = require 'assert'

#! a19dd81d-0ac0-471c-81a9-dc26c202cd67
# title: tryOnKoding_loginWithExistingUser_registerNewUser
# start_uri: /
# tags: automated
#

describe "tryOnKoding_loginWithExistingUser_registerNewUser.rfml", ->
  before -> 
    require './create_team_with_existing_account.coffee'

  describe """Click on the toggle button""", ->
    before -> 
      # implement before hook 

    it """Is it turned into green?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is 'OFF' updated as 'ON'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a text field appeared starting with '<a href="https://_' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '_Try on Koding' button appeared below that text field??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ sandbox.auth }}@{{ random.last_name }}{{ random.number }}.{{site.host}}' by pasting the url (using ctrl-v) in the address bar """, ->
    before -> 
      # implement before hook 

    it """Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'If you don't have a Koding account sign up here so you can join {{ random.last_name }}{{ random.number }}!' text below that form??""", -> 
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

    it """Do you see 'You are almost there, rainforestqa22!' title on a pop-up displayed in the center of the page??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close that modal by clicking (x) from top right corner, click on '{{ random.last_name }}{{ random.number }}' from top left corner and select 'Logout'""", ->
    before -> 
      # implement before hook 

    it """Are you successfully logged out?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'If you don't have a Koding account sign up here so you can join {{ random.last_name }}{{ random.number }}!' text below that form??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'sign up here' link?""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Join the {{ random.last_name }}{{ random.number }} team' title on a form?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'This is a public team, you can use any email address to join!' texts below the title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Email address', 'Your Username' and 'Your Password' text fields?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'SIGN UP & JOIN' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "{{ random.email }}" in the 'Email address', "{{ random.first_name }}{{ random.number }}" in the 'Your Username' and "{{ random.password }}" in the 'Your Password' field and click on 'SIGN UP & JOIN' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'You are almost there, {{ random.first_name }}{{ random.number }}!' title on a pop-up displayed in the center of the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '{{ random.last_name }}{{ random.number }}' label on top left corner??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


