$ = require 'jquery'
assert = require 'assert'

#! d392bd8d-7a02-4cf1-8761-212ab62275e9
# title: integrations
# start_uri: /
# tags: automated
#

describe "integrations.rfml", ->
  before -> 
    require './create_team_with_a_new_user.coffee'

  describe """Click on 'Dashboard' """, ->
    before -> 
      # implement before hook 

    it """Do you see 'Stacks', 'My Team', 'Koding Utilities' and 'My Account' on the left side??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Integrations'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'GitLab', 'GitLab Integration'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the toggle button next to 'GitLab Integration'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Create a new application on your GitLab instance by using this address '?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'GitLab URL' field?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Application ID'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'VIEW GUIDE' button under 'GitLab' section""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Coming soon' text??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close that tab and scroll down on Integrations tab""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Intercom'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'VIEW GUIDE' button under 'Intercom' section""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Coming soon' text??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close the tab, go to 'Chatlio' section, enter a 'Chatlio data-widget-id' and save it""", ->
    before -> 
      # implement before hook 

    it """Did you see the 'Chatlio id successfully saved!' notification??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'VIEW GUIDE' button under 'Chatlio' section""", ->
    before -> 
      # implement before hook 

    it """Is new tab opened?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Coming soon' text in new tab??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


