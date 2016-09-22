React = require 'app/react'
expect = require 'expect'
globals = require 'globals'
CodeBlock = require './index'
TestUtils = require 'react-addons-test-utils'

describe 'CodeBlock', ->

  { Simulate, renderIntoDocument } = TestUtils


  describe '::render', ->

    it 'checks rendered modal prop type', ->

      modal = renderIntoDocument(<CodeBlock cmd='copy this text'/>)

      expect(modal.props.cmd).toBeA 'string'


    it 'should render correct code block and key', ->

      modal = renderIntoDocument(<CodeBlock cmd='copy this text'/>)

      expect(modal.refs.codeblock.innerHTML).toEqual 'copy this text'


    it 'should render correct key', ->

      modal = renderIntoDocument(<CodeBlock cmd='copy this text'/>)

      key = if globals.os is 'mac' then '⌘ + C' else 'Ctrl + C'

      expect(key).toEqual modal.state.key
