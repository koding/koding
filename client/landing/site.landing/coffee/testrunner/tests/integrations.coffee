$ = require 'jquery'
assert = require 'assert'
create_team_with_a_new_user = require './create_team_with_a_new_user'

module.exports = ->

  create_team_with_a_new_user()

  describe 'integrations', ->
    describe "Close that modal by clicking (x) from top right corner and click on the team name '{{ random.last_name }}{{ random.number }}' label on top left?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Dashboard', 'Support', 'Support',  'Change Team' and 'Logout'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Dashboard' ?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Stacks', 'My Team', 'Koding Utilities' and 'My Account' on the left side??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'Integrations'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'GitLab', 'GitLab Integration'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on the toggle button next to 'GitLab Integration'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Create a new application on your GitLab instance by using this address '?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'GitLab URL' field?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Application ID'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'VIEW GUIDE' button under 'GitLab' section?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Coming soon' text??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close that tab and scroll down on Integrations tab?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Intercom'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'VIEW GUIDE' button under 'Intercom' section?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Coming soon' text??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Close the tab, go to 'Chatlio' section, enter a 'Chatlio data-widget-id' and save it?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did you see the 'Chatlio id successfully saved!' notification??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click on 'VIEW GUIDE' button under 'Chatlio' section?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is new tab opened?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see 'Coming soon' text in new tab??", (done) -> 
        assert(false, 'Not Implemented')
        done()

