$ = require 'jquery'
assert = require 'assert'

#! 49ed73a4-fd26-4c32-8db3-384fb03cebe3
# title: ide_settings
# start_uri: /
# tags: automated
#

describe "ide_settings.rfml", ->
  before -> 
    require './create_team_with_existing_user_stack_related.coffee'

  describe """Double click 'file{{random.number}}.html' file in the file tree""", ->
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


  describe """Toggle 'Enable autosave' option on in Editor Settings""", ->
    before -> 
      # implement before hook 

    it """Did it turn to green??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter some text in opened file{{random.number}}.html' file""", ->
    before -> 
      # implement before hook 

    it """Did you see a yellow dot turned to green and then disappear on file icon next to file{{random.number}} at the top??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle 'Enable autosave' option off in Editor Settings and enter some text the same file""", ->
    before -> 
      # implement before hook 

    it """Did it turn to gray?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a dot at the left of file name in the editor tab??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle 'Use soft tabs' option off in Editor Settings""", ->
    before -> 
      # implement before hook 

    it """Is 'Use soft tabs' toggle gray??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle 'Use soft tabs' option on in Editor Settings""", ->
    before -> 
      # implement before hook 

    it """Is 'Use soft tabs' toggle green??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """# Create a new row in the editor, create tabulation by pressing tab on keyboard and type 'soft tabs'""", ->
    before -> 
      # implement before hook 

    it """# Is tabulation displayed like set of dots before the 'soft tabs' text in the editor ( http://snag.gy/luhbr.jpg )??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle 'Line numbers' option on/off in Editor Settings""", ->
    before -> 
      # implement before hook 

    it """Are line numbers displayed/hidden in editor tabs??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """# Toogle 'Remove pane when last tab closed' on in Editor Settings, open some tabs and close all tabs in editor tabs""", ->
    before -> 
      # implement before hook 

    it """# Is 'Would you like us to remove the pane when there are no tabs left?' dialog displayed for the first time if user didn't this toggle?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is empty pane closed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """# Toogle 'Remove pane when last tab closed' off in Editor Settings, click on the (+) button next to the tabs on that pane and select 'Split Horizontally' option, open some files and then close all tabs in editor tabs""", ->
    before -> 
      # implement before hook 

    it """# Is the view splitted to two pieces as top and bottom panes?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is empty pane stayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle 'Use word wrapping' option on/off in Editor Settings""", ->
    before -> 
      # implement before hook 

    it """Are long lines word wrapped (displayed on multiline within the screen) in editor tabs??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle 'Show print margin' option on/off in Editor Settings""", ->
    before -> 
      # implement before hook 

    it """Are lines showing the print margin displayed/hidden in editor tabs??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle 'Highlight active line' option on/off in Editor Settings""", ->
    before -> 
      # implement before hook 

    it """Is the line where the cursor highlighted/not in editor tabs??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """# Toggle 'Show invisibles' on/off in Editor Settings""", ->
    before -> 
      # implement before hook 

    it """# Are invisible symbols like spaces, row wraps, tabs showed/hidden??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Toggle 'Use scroll past end' option on/off in Editor Settings and try to scroll any file in the editor""", ->
    before -> 
      # implement before hook 

    it """Is scrolling past the last row allowed / not-allowed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


