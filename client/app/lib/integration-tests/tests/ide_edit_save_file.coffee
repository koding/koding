$ = require 'jquery'
assert = require 'assert'

#! cb054b5e-447f-43ee-bf5a-451b06b1ed53
# title: ide_edit_save_file
# start_uri: /
# tags: automated
#

describe "ide_edit_save_file.rfml", ->
  before -> 
    require './create_team_with_existing_user_stack_related.coffee'

  describe """Enter 'file{{random.number}}.txt' file name and press Enter""", ->
    before -> 
      # implement before hook 

    it """Do you see file 'file{{random.number}}.txt' with green icon in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Double click on the 'file{{random.number}}.txt' file""", ->
    before -> 
      # implement before hook 

    it """Do you see a new editor tab opened for this file??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum' text in the editor""", ->
    before -> 
      # implement before hook 

    it """Do you see text you have entered as it is??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Mouse over the editor header where the file 'file{{random.number}}.txt'  is opened and click down arrow icon""", ->
    before -> 
      # implement before hook 

    it """Do you see Menu with 'Save', 'Save As...' and other items (like on screenshot http://snag.gy/7yOOm.jpg)??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click 'Save' in the menu""", ->
    before -> 
      # implement before hook 

    it """Did you not see any error??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Make some changes in the editor, Mouse over the editor header where the file 'file{{random.number}}.txt' is opened, click down arrow icon and Click 'Save As...' in the menu""", ->
    before -> 
      # implement before hook 

    it """Do you see the form with 'Filename', 'Select a folder' field??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter 'newfile{{random.number}}.txt' file name, select '.config' in 'Select a folder' field and click 'SAVE'""", ->
    before -> 
      # implement before hook 

    it """Do you see a new editor tab opened for 'newfile{{random.number}}.txt' file??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click '.config' in file tree list on the left""", ->
    before -> 
      # implement before hook 

    it """Do you see the 'newfile{{random.number}}.txt' file under '.config' folder??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Mouse over the editor header where the file 'newfile{{random.number}}.txt' is opened and click 'x' icon""", ->
    before -> 
      # implement before hook 

    it """Is editor tab closed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Mouse over the editor header where the file 'file{{random.number}}.txt' is opened and click 'x' icon""", ->
    before -> 
      # implement before hook 

    it """Do you see a pop-up with 'Do you want to save your changes?' title??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'DON'T SAVE' button""", ->
    before -> 
      # implement before hook 

    it """Is the editor tab closed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Double click on the 'file{{random.number}}.txt' file""", ->
    before -> 
      # implement before hook 

    it """Do you see a new editor tab opened for this file?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the same file content you entered before for the original file ('Lorem ipsum...')??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click second row in the editor, type some random text, press Enter and type some random text againg""", ->
    before -> 
      # implement before hook 

    it """Is entered text displayed correctly in the editor??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Mouse over the editor header where the file 'file{{random.number}}.txt' is opened and click 'x' icon""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Do you want to save your changes?' modal displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Don't save' and 'Save and Close' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click to 'Save and close' button""", ->
    before -> 
      # implement before hook 

    it """Is overlay closed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is editor tab with 'file{{random.number}}.txt' file also closed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Double click on the 'file{{random.number}}.txt' file in the filetree""", ->
    before -> 
      # implement before hook 

    it """Do you see a new editor tab opened for this file?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the same file content you entered before closing??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Make some changes in the editor, mouse over the editor header where the file 'file{{random.number}}.txt' is opened and click 'x' icon and click 'Don't save' button on the modal""", ->
    before -> 
      # implement before hook 

    it """Is overlay closed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is editor tab with 'file{{random.number}}.txt' file also closed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Double click on the 'file{{random.number}}.txt' file in the filetree""", ->
    before -> 
      # implement before hook 

    it """Do you see a new editor tab opened for this file without the changes from previous step??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """# Make some changes in the editor and click 'Ctrl+Option+W (Ctrl+Alt+W)' shortcut""", ->
    before -> 
      # implement before hook 

    it """# Do you see 'Do you want to save your changes?' modal displayed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Cancel', 'Don't save' and 'Save and close' buttons on the modal??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


