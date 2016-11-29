$ = require 'jquery'
assert = require 'assert'

#! aa432fee-4a31-4e8d-90c7-d07f138877ff
# title: collaboration_saveas_check_marker
# start_uri: /
# tags: automated
#

describe "collaboration_saveas_check_marker.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

  describe """Return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Do you see green warning 'ACCESS GRANTED: You can make changes now!'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close the warning and click 'Untitled.txt' file at the editor area and type 'first row' in the first row, press Enter and type 'second row' in the second row""", ->
    before -> 
      # implement before hook 

    it """Do you see text entered??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Mouse over 'Untitled.txt' and click down arrow icon displayed and click 'Save as' in the menu""", ->
    before -> 
      # implement before hook 

    it """Do you see menu expanded with 'Save', 'Save as' and other options?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a new modal with 'Filename', 'Select a folder' fields and 'Save' and 'Cancel' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter 'newfile{{random.number}}.txt' in the 'Filename' field and click 'Save'""", ->
    before -> 
      # implement before hook 

    it """Is modal closed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'newfile{{random.number}}.txt' title of the opened file instead of 'Untitled.txt'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Set cursor and the end of 'second row' in the editor on the page, press enter and enter 'third row' text""", ->
    before -> 
      # implement before hook 

    it """Do you see new row added?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a dot displayed at the left of 'newfile{{random.number}}.txt' title in the header??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the other browser window where you are logged in as 'rainforestqa99', close the browser notification if displayed""", ->
    before -> 
      # implement before hook 

    it """Do you see 'newfile{{random.number}}.txt' file opened in the editor on the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a dot displayed at the left of 'newfile{{random.number}}.txt' title in the header?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the user name marker displayed at the right of 'third row' on the page?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'newfile{{random.number}}.txt' file in the list??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


