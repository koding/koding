$ = require 'jquery'
assert = require 'assert'

#! 46af0baa-8527-44d0-9480-d36541a3699f
# title: ide_settings_terminal
# start_uri: /
# tags: automated
#

describe "ide_settings_terminal.rfml", ->
  before -> 
    require './create_team_with_existing_user_stack_related.coffee'

  describe """Click settings icon at the top of the file tree""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Editor Settings' and 'Terminal Settings' instead of file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Type 'sudo' in the terminal and press Enter""", ->
    before -> 
      # implement before hook 

    it """Do you see command and it results in the terminal??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Change 'Font' option in Terminal Settings""", ->
    before -> 
      # implement before hook 

    it """Is font in the terminal changed according to selected value??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Change 'Font size' option in Terminal Settings""", ->
    before -> 
      # implement before hook 

    it """Is font size in the terminal changed according to selected value??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Change 'Theme' option in Terminal Settings""", ->
    before -> 
      # implement before hook 

    it """Is color theme for terminal changed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """# Select '50' value for the Scrollback option in the 'Terminal Settings', type 'man -?' command in the terminal and press Enter""", ->
    before -> 
      # implement before hook 

    it """# Do you see only 50 rows of results in the terminal and other results are cut off??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """# Select '100' value for the Scrollback option in the 'Terminal Settings', type 'sudo' in the terminal and press Enter, type 'man -?' in the terminal and press Enter""", ->
    before -> 
      # implement before hook 

    it """# Do you see only 100 rows of results in the terminal and other results are cut off??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """# Select '10000' value for the Scrollback option in the 'Terminal Settings', type 'man -?' in the terminal and press Enter and repeat several times""", ->
    before -> 
      # implement before hook 

    it """# Do you see all results (up to 10000 rows) in the terminal??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """# Toggle on 'Use visual bell' in Terminal Settings, enter wrong text in terminal and press Enter""", ->
    before -> 
      # implement before hook 

    it """# Is Visual 'Bell' warning displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle on/off 'Blinking cursor' option in the Terminal Settings and click into terminal pane""", ->
    before -> 
      # implement before hook 

    it """Do you see cursor blinking??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle on 'Dim if inactive' in Terminal Settings and then click into an empty area in the text editor""", ->
    before -> 
      # implement before hook 

    it """Do you see text color is changed to white?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Does it look inactive??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle off 'Dim if inactive' in Terminal Settings and then click into an empty area in the text editor""", ->
    before -> 
      # implement before hook 

    it """Do you see text color is changed back to regular colors in the terminal?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Does it look active??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


