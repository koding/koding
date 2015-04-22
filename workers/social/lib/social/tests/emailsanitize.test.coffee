{expect}      = require "chai"
emailSanitize = require "../models/user/emailsanitize"

describe 'Gmail Validation', ->
  it 'removes dots', ->
    expected = 'indiana.jones@gmail.com'
    equals   = 'indianajones@gmail.com'

    expect(emailSanitize(expected)).to.equal equals

  it 'removes pluses and characters till @', ->
    expected = 'indiana+jones@gmail.com'
    equals   = 'indiana@gmail.com'

    expect(emailSanitize(expected)).to.equal equals

  it 'removes dots & plus and characters till @', ->
    expected = 'ind.iana+jones@gmail.com'
    equals   = 'indiana@gmail.com'

    expect(emailSanitize(expected)).to.equal equals

  it 'ignores other domains', ->
    expected = 'ind.iana+jones@koding.com'
    expect(emailSanitize(expected)).to.equal expected

  it 'removes dots & plus in googlemail as well', ->
    expected = 'ind.iana+jones@googlemail.com'
    equals   = 'indiana@googlemail.com'

    expect(emailSanitize(expected)).to.equal equals

  it 'ignores other google domains', ->
    expected = 'ind.iana+jones@gmail.uk'
    expect(emailSanitize(expected)).to.equal expected
