$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_user_stack_related = require './create_team_with_existing_user_stack_related'

module.exports = ->

  create_team_with_existing_user_stack_related()

  describe 'ide_permission', ->
    describe "Open filetree menu ( http://snag.gy/Rmoax.jpg ) and click 'New file' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new file 'NewFile.txt' added to the file tree?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is file name displayed in edit mode??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'testfile{{random.number}}.txt' folder name and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see file 'testfile{{random.number}}.txt' with arrow icon next to it in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click down arrow icon at the right of 'testfile{{random.number}}.txt' file in the file tree, mouse over 'Set permissions' section and disable 'Read' and 'Write' toggles for owner ( http://snag.gy/UhCoH.jpg ) and click 'Set'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are toggles turned to gray??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click the 'testfile{{random.number}}.txt' file in the file tree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see an overlay with 'Access Denied The file can't be opened because you don't have permission to see its contents. Read more about permissions here.' text??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click Ok then click down arrow icon at the right of 'testfile{{random.number}}.txt' file in the file tree, mouse over 'Set permissions' section and enable 'Read' toggle for owner and click 'Set'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Read' toggle turned to green??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click the 'testfile{{random.number}}.txt' file in the file tree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see an overlay with 'Read-only file This file is read-only. You won't be able to save your changes. Read more about permissions here.' text?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see new editor tab with file content opened??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click Ok then click the editor area and try to enter any text?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are you unable to make any changes in the editor??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over the editor header where the file 'testfile{{random.number}}.txt' is opened and click down 'x' icon?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is editor tab closed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click down arrow icon at the right of 'testfile{{random.number}}.txt' file in the file tree, mouse over 'Set permissions' section and enable 'Read' and 'Write' toggles for owner and click 'Set'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are toggles turned to green??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click the 'testfile{{random.number}}.txt' file in the file tree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new editor tab with file content opened??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click the editor area and try to enter any text?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is entered text displayed correctly in the editor?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Do you see a dot at the left of file name in the editor tab??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click down arrow icon at the right of 'testfile{{random.number}}.txt' file in the file tree, mouse over 'Set permissions' section and diable all toggles for all people and click 'Set'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are toggles turned to gray??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click the 'testfile{{random.number}}.txt' file in the file tree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see an overlay with 'Access Denied The file can't be opened because you don't have permission to see its contents. Read more about permissions here.' text??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click down arrow icon at the right of 'testfile{{random.number}}.txt' file in the file tree, mouse over 'Set permissions' section and enable all toggles for all people and click 'Set'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are toggles turned to green??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open filetree menu ( http://snag.gy/Rmoax.jpg ) and click 'New folder' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new folder 'NewFolder' added to the file tree?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is folder name displayed in edit mode??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '{{random.address_state}}{{random.number}}' folder name and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see folder '{{random.address_state}}{{random.number}}' with arrow icon next to it in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open menu for  '{{random.address_state}}{{random.number}}' folder in the file tree, mouse over 'Set Permissions' section, disable all three 'Execute' toggles ( http://snag.gy/6Jyg9.jpg )  and click 'Set'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are 'Execute' toggles turned to gray??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open menu for '{{random.address_state}}{{random.number}}' folder in the file tree and click 'New Folder'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see red warning 'Permission denied!' at the top of file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open menu for '{{random.address_state}}{{random.number}}' folder in the file tree, mouse over 'Set Permissions' section, disable  'Write' toggle for owner and click 'Set'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is 'Write' toggle turned to gray??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click file 'testfile{{random.number}}.txt' in the file tree and then drag&drop it to the '{{random.address_state}}{{random.number}}' folder?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see red warning 'Permission denied!' at the top of file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open menu for '{{random.address_state}}{{random.number}}' folder in the file tree, mouse over 'Set Permissions' section, enable 'Write' and enable 'Execute' toggle for owner and click 'Set'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are 'Write' and 'Execute' toggles turned to green??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click file 'testfile{{random.number}}.txt' in the file tree and then drag&drop it to the '{{random.address_state}}{{random.number}}' folder?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is file moved to the '{{random.address_state}}{{random.number}}' folder??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open menu for '{{random.address_state}}{{random.number}}' folder in the file tree, mouse over 'Set Permissions' section, disable 'Read' and 'Write' toggles for owner and click 'Set'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are toggles turned to gray??", (done) -> 
        assert(false, 'Not Implemented')
        done()

