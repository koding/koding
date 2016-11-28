$ = require 'jquery'
assert = require 'assert'

#! 51bafaa0-0b4e-441f-af89-9d32a516d921
# title: ide_terminal
# start_uri: /
# tags: automated
#

describe "ide_terminal.rfml", ->
  before -> 
    require './create_team_with_existing_user_stack_related.coffee'

  describe """Enter '{{random.address_state}}{{random.number}}' folder name and press Enter""", ->
    before -> 
      # implement before hook 

    it """Do you see a folder '{{random.address_state}}{{random.number}}' with arrow icon next to it in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click to folder '{{random.address_state}}{{random.number}}' and then click to down arrow icon at the right hand of the folder. Click 'Terminal from here' in the menu opened ( http://snag.gy/a8gQD.jpg )""", ->
    before -> 
      # implement before hook 

    it """Do you see a new terminal opened?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see ' ~/{{random.address_state}}{{random.number}}_' in the terminal??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click down arrow icon in the terminal header and click 'Rename' in the menu ( http://snag.gy/KlOHf.jpg )""", ->
    before -> 
      # implement before hook 

    it """Do you see an edit mode for terminal tab title is displayed in edit mode??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter 'Terminal {{random.number}}' as a title and press Enter""", ->
    before -> 
      # implement before hook 

    it """Is terminal tab renamed to  'Terminal {{random.number}}' ??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click '+' icon at the right of the terminal and select New Terminal -> New Session (http://snag.gy/UnOoo.jpg)""", ->
    before -> 
      # implement before hook 

    it """Do you see new terminal tab opened??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Type 'sudo' in terminal and press Enter, type 'la' in terminal and press Enter""", ->
    before -> 
      # implement before hook 

    it """Do you see results of the commands in the terminal??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click down arrow icon in the terminal header and click 'Suspend' in the menu ( http://snag.gy/KlOHf.jpg )""", ->
    before -> 
      # implement before hook 

    it """Is terminal closed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click '+' icon at the right of the terminal and mouse over 'New Terminal' section""", ->
    before -> 
      # implement before hook 

    it """Do you see menu with one or more 'Session (...)' items?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see at least one 'Session (...)' item that not-grayed (like on screenshot http://snag.gy/UUVSo.jpg )??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Mouse over some not-grayed 'Session (...)' item in the menu and click 'Open' for this item""", ->
    before -> 
      # implement before hook 

    it """Do you see new terminal tab opened (restored)??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click '+' icon at the right of the terminal and mouse over 'New Terminal' section, mouse over some grayed 'Session (...)' item and click 'Terminate'""", ->
    before -> 
      # implement before hook 

    it """Is one of the active terminals closed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click '+' icon at the right of the terminal and mouse over 'New Terminal' section and click 'Terminate all' in the menu""", ->
    before -> 
      # implement before hook 

    it """Are all terminal tabs closed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Click 'No' on the 'Would you like us to remove the pane when there are no tabs left?' modal if it's displayed ( http://snag.gy/WynLF.jpg )?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """# Click '+' icon in the header where terminals were opened and click 'New Drawing Board' in the menu""", ->
    before -> 
      # implement before hook 

    it """# Do you see a new tab with drawing board opened??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """# Try to draw something using a mouse on the drawing board area""", ->
    before -> 
      # implement before hook 

    it """# Are you able to draw??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click '+' icon at the right of the terminal and select New Terminal -> New Session (http://snag.gy/UnOoo.jpg)""", ->
    before -> 
      # implement before hook 

    it """Do you see new terminal tab opened??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Refresh the page""", ->
    before -> 
      # implement before hook 

    it """Do you see all opened terminals, drawing boards are remembered??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click '+' icon at the right of the file name in the editor header and click 'Enter Fullscreen' ( http://snag.gy/rb5Po.jpg )""", ->
    before -> 
      # implement before hook 

    it """Is editor displayed in fullscreen mode??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click '+' icon at the right of the file name in the editor header and click 'Exit Fullscreen'""", ->
    before -> 
      # implement before hook 

    it """Is editor displayed in normal mode??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click 'Fullscreen' icon in the top right corner of the editor header ( http://snag.gy/YMM7u.jpg )""", ->
    before -> 
      # implement before hook 

    it """Is editor displayed in fullscreen mode??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click again 'Fullscreen' icon in the top right corner of the editor header ( http://snag.gy/YMM7u.jpg )""", ->
    before -> 
      # implement before hook 

    it """Is editor displayed in normal mode??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


