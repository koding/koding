$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_user_stack_related = require './create_team_with_existing_user_stack_related'

module.exports = ->

  create_team_with_existing_user_stack_related()

  describe 'ide_settings', ->
    describe "Open filetree menu by clicking to arrow next to '/home/rainforestqa99' in the middle section, click 'New file', enter 'file{{random.number}}.html' file name and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new file named 'file{{random.number}}.html' with a blue note icon in file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click 'file{{random.number}}.html' file in the file tree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new editor tab opened for this file??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click settings icon at the top of the file tree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Editor Settings' and 'Terminal Settings' instead of file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle 'Enable autosave' option on in Editor Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did it turn to green??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter some text in opened file{{random.number}}.html' file?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did you see a yellow dot turned to green and then disappear on file icon next to file{{random.number}} at the top??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle 'Enable autosave' option off in Editor Settings and enter some text the same file?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did it turn to gray?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a dot at the left of file name in the editor tab??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle 'Use soft tabs' option off in Editor Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Use soft tabs' toggle gray??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle 'Use soft tabs' option on in Editor Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Use soft tabs' toggle green??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "# Create a new row in the editor, create tabulation by pressing tab on keyboard and type 'soft tabs'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "# Is tabulation displayed like set of dots before the 'soft tabs' text in the editor ( http://snag.gy/luhbr.jpg )??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle 'Line numbers' option on/off in Editor Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are line numbers displayed/hidden in editor tabs??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "# Toogle 'Remove pane when last tab closed' on in Editor Settings, open some tabs and close all tabs in editor tabs?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "# Is 'Would you like us to remove the pane when there are no tabs left?' dialog displayed for the first time if user didn't this toggle?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is empty pane closed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "# Toogle 'Remove pane when last tab closed' off in Editor Settings, click on the (+) button next to the tabs on that pane and select 'Split Horizontally' option, open some files and then close all tabs in editor tabs?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "# Is the view splitted to two pieces as top and bottom panes?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is empty pane stayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle 'Use word wrapping' option on/off in Editor Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are long lines word wrapped (displayed on multiline within the screen) in editor tabs??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle 'Show print margin' option on/off in Editor Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are lines showing the print margin displayed/hidden in editor tabs??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle 'Highlight active line' option on/off in Editor Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is the line where the cursor highlighted/not in editor tabs??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "# Toggle 'Show invisibles' on/off in Editor Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "# Are invisible symbols like spaces, row wraps, tabs showed/hidden??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle 'Use scroll past end' option on/off in Editor Settings and try to scroll any file in the editor?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is scrolling past the last row allowed / not-allowed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

