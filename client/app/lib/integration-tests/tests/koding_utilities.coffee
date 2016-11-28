$ = require 'jquery'
assert = require 'assert'

#! 63991135-c635-4452-a10a-4a7d936cea1b
# title: koding_utilities
# start_uri: /
# tags: automated
#

describe "koding_utilities.rfml", ->
  before -> 
    require './create_team_with_a_new_user.coffee'

  describe """Enter "rainforestqa22@koding.com" in the 'Email' field and uncheck admin column then click to 'SEND INVITES'""", ->
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

    it """Do you see 'You are almost there, rainforestqa22!' titled pop-up??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close that pop-up by clicking (x) icon from top right and click on the team name '{{ random.last_name }}{{ random.number }}' label on top left""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Dashboard', 'Support', 'Support',  'Change Team' and 'Logout'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Dashboard'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Stacks', 'My Team', 'Koding Utilities' and 'My Account' on the left side??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Koding Utilities'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'KD CLI', 'Koding OS X App'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser and click on 'Koding Utilities'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'KD CLI', 'Koding OS X App'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on the KD command line which starts with 'curl -sL ...'""", ->
    before -> 
      # implement before hook 

    it """Did you see 'Copied to clipboard!' notification??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """# Click on 'VIEW GUIDE' button""", ->
    before -> 
      # implement before hook 

    it """# Is new tab opened?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Use your own IDE', 'Introduction', 'Step 1: Get the kd install command' in new tab??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """# Close the newly opened tab, go to 'Koding OS X App' section and click on 'DOWNLOAD' button""", ->
    before -> 
      # implement before hook 

    it """Go to 'Koding OS X App' section and click on 'DOWNLOAD' button?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'VIEW GUIDE' button""", ->
    before -> 
      # implement before hook 

    it """Is new tab opened?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Koding Desktop App' in new tab??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close the tab, go to 'Koding Button' section and enable 'Try On Koding' button""", ->
    before -> 
      # implement before hook 

    it """Do you see code block which start with '<a href="https:// ...'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on code block""", ->
    before -> 
      # implement before hook 

    it """Did you see 'Copied to clipboard!' notification??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch the incognito window and go to 'Koding Button' section""", ->
    before -> 
      # implement before hook 

    it """Is 'Try On Koding' button not visible?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see code block which start with '<a href="https:// ...'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Switch the first browser and disable 'Try On Koding' button""", ->
    before -> 
      # implement before hook 

    it """Is 'Try on Koding' button removed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is code block removed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see only 'VIEW GUIDE'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'VIEW GUIDE' button""", ->
    before -> 
      # implement before hook 

    it """Is new tab opened?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Try on Koding Button', 'What is Koding and why use Try on Koding button?' in new tab??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close the tab, go to 'API Access' section, enable 'Enable API Access'""", ->
    before -> 
      # implement before hook 

    it """Do you see 'No tokens have been created yet. When you create, they will be listed here.'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'VIEW GUIDE', 'ADD NEW API TOKEN'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'ADD NEW API TOKEN'""", ->
    before -> 
      # implement before hook 

    it """Do you see token list with 'COPY', 'DELETE' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'Delete' button""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Are you sure?' overlay??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'YES'""", ->
    before -> 
      # implement before hook 

    it """Did it removed from token list?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'No tokens have been created yet. When you create, they will be listed here.'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'VIEW GUIDE' button""", ->
    before -> 
      # implement before hook 

    it """Is new tab opened?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'API Tokens', 'Coming soon:' in new tab??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close tab and return same section, disable 'Enable API Access'""", ->
    before -> 
      # implement before hook 

    it """Is 'ADD NEW API TOKEN' button disabled??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


