{ expect }   = require 'chai'

sanitize     = require './emailsanitize'

describe 'Gmail Validation', ->
  it 'downcases', ->
    expected = 'INDIANAJONES@gmail.com'
    expect(sanitize(expected)).to.equal expected.toLowerCase()

  it 'trims whitespace', ->
    expected = '  indianajones@gmail.com  '
    expect(sanitize(expected)).to.equal expected.trim()

  it 'removes dots', ->
    expected = 'indiana.jones@gmail.com'
    equals   = 'indianajones@gmail.com'

    expect(sanitize(expected, { excludeDots: yes })).to.equal equals

  it 'removes dots before plus label', ->
    expected = 'ind.iana+jones@gmail.com'
    equals   = 'indiana+jones@gmail.com'

    expect(sanitize(expected, { excludeDots: yes })).to.equal equals

  it 'removes dots till +', ->
    expected = 'ind.iana+j.o.n.e.s@gmail.com'
    equals   = 'indiana+j.o.n.e.s@gmail.com'

    expect(sanitize(expected, { excludeDots: yes })).to.equal equals

  it 'removes plus label and characters till @', ->
    expected = 'indiana+jones@gmail.com'
    equals   = 'indiana@gmail.com'

    expect(sanitize(expected, { excludePlus: yes })).to.equal equals

  it 'removes dots & plus label and characters till @', ->
    expected = 'ind.iana+jones@gmail.com'
    equals   = 'indiana@gmail.com'

    expect(sanitize(expected, { excludeDots: yes, excludePlus: yes })).to.equal equals

  it 'ignores other domains', ->
    expected = 'ind.iana+jones@koding.com'
    expect(sanitize(expected)).to.equal expected

  it 'removes dots & plus in googlemail as well', ->
    expected = 'ind.iana+jones@googlemail.com'
    equals   = 'indiana@googlemail.com'

    expect(sanitize(expected, { excludeDots: yes, excludePlus: yes })).to.equal equals

  it 'ignores other google domains', ->
    expected = 'ind.iana+jones@gmail.uk'
    expect(sanitize(expected)).to.equal expected
