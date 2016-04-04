kd              = require 'kd'
expect          = require 'expect'
stripHTMLtoText = require 'app/util/stripHTMLtoText'

describe 'StripHTMLToText', ->

  it 'should produce correct text', ->

    expect(stripHTMLtoText '').toEqual ''
    expect(stripHTMLtoText 'plain text').toEqual 'plain text'
    expect(stripHTMLtoText 'text with <p>html tag</p>').toEqual 'text with html tag'
