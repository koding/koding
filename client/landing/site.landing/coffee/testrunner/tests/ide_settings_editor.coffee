$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_user_stack_related = require './create_team_with_existing_user_stack_related'

module.exports = ->

  create_team_with_existing_user_stack_related()

  describe 'ide_settings_editor', ->
    describe "Open filetree menu by clicking into down arrow next to /home/rainforestqa99 then click 'New file' and then type '{{random.address_city}}{{random.number}}.html' file name (remove .txt extension) and press ENTER?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a new file named '{{random.address_city}}{{random.number}}.html' added to the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click '{{random.address_city}}{{random.number}}.html' file in the file tree?", ->
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

    describe "Toggle 'Trim trailing whitespaces' option on in Editor Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Trim trailing whitespaces' toggle green??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Insert tabs by pressing tab on keyboard, type some spaces and press Enter. Move mouse over to the editor tab where the file '{{random.address_city}}{{random.number}}.html' above of editor pane and click arrow icon and then click to 'Save' action in menu displayed?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are all spaces and tabs removed from the line you entered??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle 'Trim trailing whitespaces' option off in Editor Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Trim trailing whitespaces' toggle gray??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Disable 'Enable Autocomplete' toggle in the 'Editor Settings'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Enable Autocomplete' toggle gray??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click editor area, create a new line and type 'tested test' (type, not copy/paste)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the text entered without any hints at the bottom (hint like this http://snag.gy/HdTHS.jpg shouldn't be displayed)??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enable 'Enable Autocomplete' toggle in the 'Editor Settings'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Enable Autocomplete' toggle green??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click editor area, create a new line and type 'test' (type, not copy/paste)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see the text entered with a hint at the bottom of the text containing words with 'test' in it (like on screenshot http://snag.gy/LnDQx.jpg )??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle 'Enable emmet' on in Editor Settings. Delete all the text in the editor. Type 'html:5' and then press TAB key?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Does 'html:5' replaced with '<h5 id='' ></h5>'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle 'Enable snippets' on?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Did it turn to green??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle 'Enable brace, tag completion' off,  clear file content and type '<html>' (type, not copy/paste)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is tag not completed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle 'Enable brace, tag completion' on,  clear file content and type '<html>' (type, not copy/paste)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is tag completed with </html>??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Select 'Vim' for 'Key binding' option in Editor Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see red cursor??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Select 'Emacs' for 'Key binding' option in Editor Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see green cursor??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Select 'Default' for 'Key binding' option in Editor Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see default cursor??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Change 'Font size' option in Editor Settings (try different settings and return to the 12px as result)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is font size in the editor changed according to selected value??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Change 'Theme' option in Editor Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is color theme for editor changed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Change value for 'Tab size' option, create a new line in the editor, create tabulation by pressing tab on keyboard and type 'new line'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is tabulation displayed the number of spaces equals the selected value in the settings??", (done) -> 
        assert(false, 'Not Implemented')
        done()

