$ = require 'jquery'
assert = require 'assert'

#! bed6d3f5-562d-422a-a94a-ab945a0e484d
# title: ide_find
# start_uri: /
# tags: automated
#

describe "ide_find.rfml", ->
  before -> 
    require './create_team_with_existing_user_stack_related.coffee'

  describe """Mouse over the editor header where the file '.profile' is opened, click down arrow icon and click 'Find' in the menu ( http://snag.gy/qurdn.jpg )""", ->
    before -> 
      # implement before hook 

    it """Do you see Find form with one 'Find' input field at the bottom of the page??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter 'exists' in the Find field and press Enter""", ->
    before -> 
      # implement before hook 

    it """Are all matched words highlighted with blue borders in the editor??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click 'x' icon in the Find form and click any place in the editor where '.profile' file is opened""", ->
    before -> 
      # implement before hook 

    it """Is find form closed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is highlighting removed in the editor?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Double click 'exist' word in the editor area""", ->
    before -> 
      # implement before hook 

    it """Are all matched words highlighted with blue borders in the editor??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Mouse over the editor header where the file '.profile' is opened, click down arrow icon and click 'Find and Replace' in the menu""", ->
    before -> 
      # implement before hook 

    it """Do you see a form with two 'Find' and 'Replace' input fields at the bottom of the page??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter 'then' in the Find field, '111111' in the Replace field and click 'Replace All'""", ->
    before -> 
      # implement before hook 

    it """Are all matched words replaced with '111111'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Mouse over the editor header where the file '.profile' is opened, click down arrow icon and click 'Go to Line' in the menu""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Go to line' modal opened with green 'GO' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter '7' in the 'Go to line' field and click 'GO' button""", ->
    before -> 
      # implement before hook 

    it """Is cursor moved to the row #7??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open menu for the '.bash_logout' file in file tree and click 'Duplicate' ( http://snag.gy/d5imL.jpg )""", ->
    before -> 
      # implement before hook 

    it """Do you see new file '_1.bash_logout' displayed in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open menu for the '.bashrc' file in file tree and click 'Duplicate' """, ->
    before -> 
      # implement before hook 

    it """Do you see new file '_1.bashrc' displayed in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Mouse over the editor header where the file '.profile' is opened, click down arrow icon and click 'Find file by name' in the menu""", ->
    before -> 
      # implement before hook 

    it """Do you see search form on the screen with 'Type a file name to search' input field??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Type 'bash' in the 'Type a file name to search' input field""", ->
    before -> 
      # implement before hook 

    it """Are search performed in real time and search results displayed below the input field?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Are search results contain 2 rows containing:  '_1.bashrc' and '_1.bash_logout'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click '_1.bash_logout' in the search result""", ->
    before -> 
      # implement before hook 

    it """Do you see new editor tab opened with  '_1.bash_logout' file content??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """""", ->
    before -> 
      # implement before hook 


