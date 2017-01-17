$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_user_stack_related = require './create_team_with_existing_user_stack_related'

module.exports = ->

  create_team_with_existing_user_stack_related()

  describe 'ide_find', ->
    describe "Double click '.profile' file in the file tree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new editor tab opened with this file content??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over the editor header where the file '.profile' is opened, click down arrow icon and click 'Find' in the menu ( http://snag.gy/qurdn.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see Find form with one 'Find' input field at the bottom of the page??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'exists' in the Find field and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are all matched words highlighted with blue borders in the editor??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click 'x' icon in the Find form and click any place in the editor where '.profile' file is opened?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is find form closed?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Is highlighting removed in the editor??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Double click 'exist' word in the editor area?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are all matched words highlighted with blue borders in the editor??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over the editor header where the file '.profile' is opened, click down arrow icon and click 'Find and Replace' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see a form with two 'Find' and 'Replace' input fields at the bottom of the page??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter 'then' in the Find field, '111111' in the Replace field and click 'Replace All'?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are all matched words replaced with '111111'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over the editor header where the file '.profile' is opened, click down arrow icon and click 'Go to Line' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Go to line' modal opened with green 'GO' button??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Enter '7' in the 'Go to line' field and click 'GO' button?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is cursor moved to the row #7??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open menu for the '.bash_logout' file in file tree and click 'Duplicate' ( http://snag.gy/d5imL.jpg )?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new file '_1.bash_logout' displayed in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Open menu for the '.bashrc' file in file tree and click 'Duplicate' ?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new file '_1.bashrc' displayed in the file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Mouse over the editor header where the file '.profile' is opened, click down arrow icon and click 'Find file by name' in the menu?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see search form on the screen with 'Type a file name to search' input field??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Type 'bash' in the 'Type a file name to search' input field?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Are search performed in real time and search results displayed below the input field?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Are search results contain 2 rows containing:  '_1.bashrc' and '_1.bash_logout'??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click '_1.bash_logout' in the search result?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new editor tab opened with  '_1.bash_logout' file content??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "?", (done) -> 
        assert(false, 'Not Implemented')
        done()

