$ = require 'jquery'
assert = require 'assert'

#! d1498a2b-2de9-4fa7-a0c8-eb6952b8ec95
# title: collaboration_create_save_files
# start_uri: /
# tags: automated
#

describe "collaboration_create_save_files.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

  describe """Return to the incognito browser window""", ->
    before -> 
      # implement before hook 

    it """Do you see green warning 'ACCESS GRANTED: You can make changes now!'??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close the warning and click 'Untitled.txt' file at the editor area and type '{{random.address_city}}' in the first row""", ->
    before -> 
      # implement before hook 

    it """Do you see text entered??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Mouse over 'Untitled.txt', click down arrow icon displayed ans click Save in menu (like on screenshot http://snag.gy/zNMRr.jpg )""", ->
    before -> 
      # implement before hook 

    it """Do you see a new modal with 'Filename', 'Select a folder' fields and 'Save' and 'Cancel' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter 'file1.txt' in the 'Filename' field and click 'Save'""", ->
    before -> 
      # implement before hook 

    it """Is modal closed?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the 'file1.txt' title of the opened file instead of 'Untitled.txt'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see the file 'file1.txt' in the file tree??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """""", ->
    before -> 
      # implement before hook 

