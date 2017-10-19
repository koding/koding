traverse = require 'traverse'
inherit = require './inheritOptionFlags'

{ expect }  = require '../workers/social/testhelper'

test_options =
  level1a       :
    level2a     : 'test-level2a-value'
    level2b     :
      level3a   : 'test-level3a-value'
    level2c     :
      level3b   : 'test-level3b-value'
      level3c   : 'test-level3c-value'
  level1b       : 'test-level1b-value'
  level1d       : 'test-level1d-value'

test_credentials =
  level1a       :
    level2a     : 'credentials-level2a-value'
    level2b     :
      level3a   : 'credentials-level3a-value'
    level2c     :
      level3b   : 'credentials-level3b-value'
      level3c   : 'credentials-level3c-value'
      level3d   : 'credentials-level3d-value'
  level1b       : 'credentials-level1b-value'
  level1c       :
    level2d     :
      level3e   : 'credentials-level3e-value'


getValues = (obj) -> traverse(obj).reduce(((values, x) ->
  if @isLeaf
    values.push x
  values
), [])

runTests = ->
  credential_vals_before = getValues(test_credentials)
  options_values = getValues(test_options)

  inherit test_credentials, test_options

  credentials_values = getValues(test_credentials)
  # Tests for inheritance until third level
  it 'should set credentials-level1b-value to test-level1b-value', ->
    result   = JSON.stringify test_credentials.level1b
    expected = JSON.stringify test_options.level1b
    expect(result).to.be.equal expected

  it 'should set credentials-level2a-value to test-level2a-value', ->
    result   = JSON.stringify test_credentials.level1a.level2a
    expected = JSON.stringify test_options.level1a.level2a
    expect(result).to.be.equal expected

  it 'should set credentials-level3a-value to test-level3a-value', ->
    result   = JSON.stringify test_credentials.level1a.level2b.level3a
    expected = JSON.stringify test_options.level1a.level2b.level3a
    expect(result).to.be.equal expected
  # ---

  it 'should not set credentials-level3d-value to anything', ->
    result   = JSON.stringify test_credentials.level1c.level2d.level3d
    expected = JSON.stringify test_credentials.level1c.level2d.level3d
    expect(result).to.be.equal expected

  # No matching property in credentials
  it 'should not set any credential values to test-level1d-value', ->
    result   = 'test-level1d-value' in credentials_values
    expected = false
    expect(result).to.be.equal expected

  # Comparing changed and unchanged values
  it 'credential values that are not in options should remain unchanged', ->
    not_changed = false
    for val in credential_vals_before
      if val not in options_values and val in credentials_values
        not_changed = true
    result   = not_changed
    expected = true
    expect(result).to.be.equal expected

runTests()
