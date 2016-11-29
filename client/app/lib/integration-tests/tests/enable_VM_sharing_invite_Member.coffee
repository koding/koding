$ = require 'jquery'
assert = require 'assert'

#! 2f953286-4d03-47aa-9665-b80e2cd03c5a
# title: enable_VM_sharing_invite_Member
# start_uri: /
# tags: embedded
#

describe "enable_VM_sharing_invite_Member.rfml", ->
  before -> 
    require './create_team_with_existing_user_stack_related.coffee'

  describe """Click on 'Edit Name' link next to 'Edit VM Name' section, delete 'aws-instance', type 'test' instead and hit ENTER key (like in screencast here: http://recordit.co/8HU8DZyTtX)""", ->
    before -> 
      # implement before hook 

    it """Do you see that it's updated??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Click on 'My Team' from left vertical menu""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Team Settings', 'Permissions' and 'Send Invites' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Please scroll down to see 'Send Invites' section if it doesn't visible initially?""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22@koding.com" in 'Email' field of the first row of 'Send Invites' section, uncheck the 'Admin' checkbox at the end of the row and then click on 'SEND INVITES' below (like in screencast here: http://recordit.co/2zVr5nwBzH)""", ->
    before -> 
      # implement before hook 

    it """Have you seen 'Invitation is sent to rainforestqa22@koding.com' message displayed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Open a new incognito window by clicking on the 3 dots on the top corner of the browser and selecting 'New Incognito Window' and then go to '{{ sandbox.auth }}@{{ random.last_name }}{{ random.number }}.{{site.host}}' by pasting the url (using ctrl-v) in the address bar""", ->
    before -> 
      # implement before hook 

    it """Do you see 'Sign in to {{ random.last_name }}{{ random.number }}' text, 'Your Username or Email' and 'Your Password' fields and a 'SIGN IN' button??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter "rainforestqa22" both in the 'Your Username or Email' and 'Your Password' fields and click on 'SIGN IN' button""", ->
    before -> 
      # implement before hook 

    it """Are you successfully logged in?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '{{ random.last_name }}{{ random.number }}' label at the top left corner?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see '_Aws Stack' title?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Instructions', 'Credentials' and 'Build Stack' sections?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'Read Me' text and a 'NEXT' and 'VIEW STACK TEMPLATE' buttons on the bottom?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'STACKS', '_Aws Stack' and 'aws-instance' labels on left sidebar??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Return to the first browser, click on 'Stacks' from left vertical menu and click on the toggle button next to 'VM Sharing'""", ->
    before -> 
      # implement before hook 

    it """Is the label updated as 'ON'?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is it turned to green?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Has a text-box with 'Type a username' label appeared?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'This VM has not yet been shared with anyone.' text below that text box??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Enter 'rainforestqa22' in the text box, hit enter and wait for a few seconds for process to be completed""", ->
    before -> 
      # implement before hook 

    it """Is 'rainforestqa22' added below 'Type a username' text box?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Is 'This VM has not yet been shared with anyone.' text removed??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


  describe """Close the modal by clicking close button on top right corner then switch to the incognito window""", ->
    before -> 
      # implement before hook 

    it """Do you see 'test(@rainforestqa99)' below 'SHARED VMS' title on left sidebar?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see a pop-up appeared next to it?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you see 'wants to share their VM with you.' text in that pop-up?""", -> 
      assert(false, 'Not Implemented')
      #assertion here

    it """Do you also see 'REJECT' and 'ACCEPT' buttons??""", -> 
      assert(false, 'Not Implemented')
      #assertion here


