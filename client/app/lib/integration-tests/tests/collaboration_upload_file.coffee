$ = require 'jquery'
assert = require 'assert'

#! 0a7fcb96-89ed-4351-9bac-ce2ec89233d7
# title: collaboration_upload_file
# start_uri: /
# tags: automated
#

describe "collaboration_upload_file.rfml", ->
  before -> 
    require './collaboration_start_session_invite_member.coffee'

