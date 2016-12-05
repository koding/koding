$ = require 'jquery'
assert = require 'assert'
create_team_with_existing_user_stack_related = require './create_team_with_existing_user_stack_related'

module.exports = ->

  create_team_with_existing_user_stack_related()

  describe 'ide_settings_terminal', ->
    describe "Click '+' icon at the right of terminal and select New Terminal -> New Session (http://snag.gy/UnOoo.jpg)?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see new terminal tab opened??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Click settings icon at the top of the file tree?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see 'Editor Settings' and 'Terminal Settings' instead of file tree??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Type 'sudo' in the terminal and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see command and it results in the terminal??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Change 'Font' option in Terminal Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is font in the terminal changed according to selected value??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Change 'Font size' option in Terminal Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is font size in the terminal changed according to selected value??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Change 'Theme' option in Terminal Settings?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Is color theme for terminal changed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "# Select '50' value for the Scrollback option in the 'Terminal Settings', type 'man -?' command in the terminal and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "# Do you see only 50 rows of results in the terminal and other results are cut off??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "# Select '100' value for the Scrollback option in the 'Terminal Settings', type 'sudo' in the terminal and press Enter, type 'man -?' in the terminal and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "# Do you see only 100 rows of results in the terminal and other results are cut off??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "# Select '10000' value for the Scrollback option in the 'Terminal Settings', type 'man -?' in the terminal and press Enter and repeat several times?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "# Do you see all results (up to 10000 rows) in the terminal??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "# Toggle on 'Use visual bell' in Terminal Settings, enter wrong text in terminal and press Enter?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "# Is Visual 'Bell' warning displayed??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle on/off 'Blinking cursor' option in the Terminal Settings and click into terminal pane?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see cursor blinking??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle on 'Dim if inactive' in Terminal Settings and then click into an empty area in the text editor?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see text color is changed to white?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Does it look inactive??", (done) -> 
        assert(false, 'Not Implemented')
        done()

    describe "Toggle off 'Dim if inactive' in Terminal Settings and then click into an empty area in the text editor?", ->
      before (done) -> 
        # implement before hook 
        done()


      it "Do you see text color is changed back to regular colors in the terminal?", (done) -> 
        assert(false, 'Not Implemented')
        done()

      it "Does it look active??", (done) -> 
        assert(false, 'Not Implemented')
        done()

