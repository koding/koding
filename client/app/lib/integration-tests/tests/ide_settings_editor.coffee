$ = require 'jquery'
assert = require 'assert'

#! 04b2f960-9f9d-4f9b-8cff-ce4068748c90
# title: ide_settings_editor
# start_uri: /
# tags: automated
#

describe "ide_settings_editor.rfml", ->
  before -> 
    require './create_team_with_existing_user_stack_related.coffee'

  describe """Double click '{{random.address_city}}{{random.number}}.html' file in the file tree""", ->
    before -> 
      # implement before hook 

    it """Do you see a new editor tab opened for this file??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click settings icon at the top of the file tree""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Editor Settings' and 'Terminal Settings' instead of file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle 'Trim trailing whitespaces' option on in Editor Settings""", ->
    before -> 
      # implement before hook 

    it """Is 'Trim trailing whitespaces' toggle green??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Insert tabs by pressing tab on keyboard, type some spaces and press Enter. Move mouse over to the editor tab where the file '{{random.address_city}}{{random.number}}.html' above of editor pane and click arrow icon and then click to 'Save' action in menu displayed""", ->
    before -> 
      # implement before hook 

    it """Are all spaces and tabs removed from the line you entered??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle 'Trim trailing whitespaces' option off in Editor Settings""", ->
    before -> 
      # implement before hook 

    it """Is 'Trim trailing whitespaces' toggle gray??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Disable 'Enable Autocomplete' toggle in the 'Editor Settings'""", ->
    before -> 
      # implement before hook 

    it """Is 'Enable Autocomplete' toggle gray??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click editor area, create a new line and type 'tested test' (type, not copy/paste)""", ->
    before -> 
      # implement before hook 

    it """Do you see the text entered without any hints at the bottom (hint like this http://snag.gy/HdTHS.jpg shouldn't be displayed)??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enable 'Enable Autocomplete' toggle in the 'Editor Settings'""", ->
    before -> 
      # implement before hook 

    it """Is 'Enable Autocomplete' toggle green??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click editor area, create a new line and type 'test' (type, not copy/paste)""", ->
    before -> 
      # implement before hook 

    it """Do you see the text entered with a hint at the bottom of the text containing words with 'test' in it (like on screenshot http://snag.gy/LnDQx.jpg )??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle 'Enable emmet' on in Editor Settings. Delete all the text in the editor. Type 'html:5' and then press TAB key""", ->
    before -> 
      # implement before hook 

    it """Does 'html:5' replaced with '<h5 id="" ></h5>'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle 'Enable snippets' on""", ->
    before -> 
      # implement before hook 

    it """Did it turn to green??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle 'Enable brace, tag completion' off,  clear file content and type '<html>' (type, not copy/paste)""", ->
    before -> 
      # implement before hook 

    it """Is tag not completed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle 'Enable brace, tag completion' on,  clear file content and type '<html>' (type, not copy/paste)""", ->
    before -> 
      # implement before hook 

    it """Is tag completed with </html>??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Select 'Vim' for 'Key binding' option in Editor Settings""", ->
    before -> 
      # implement before hook 

    it """Do you see red cursor??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Select 'Emacs' for 'Key binding' option in Editor Settings""", ->
    before -> 
      # implement before hook 

    it """Do you see green cursor??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Select 'Default' for 'Key binding' option in Editor Settings""", ->
    before -> 
      # implement before hook 

    it """Do you see default cursor??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Change 'Font size' option in Editor Settings (try different settings and return to the 12px as result)""", ->
    before -> 
      # implement before hook 

    it """Is font size in the editor changed according to selected value??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Change 'Theme' option in Editor Settings""", ->
    before -> 
      # implement before hook 

    it """Is color theme for editor changed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Change value for 'Tab size' option, create a new line in the editor, create tabulation by pressing tab on keyboard and type 'new line'""", ->
    before -> 
      # implement before hook 

    it """Is tabulation displayed the number of spaces equals the selected value in the settings??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


