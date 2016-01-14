React     = require 'kd-react'
ReactDOM  = require 'react-dom'
expect    = require 'expect'
Header    = require '../headerview'
TestUtils = require 'react-addons-test-utils'

describe 'BrowsePublicChannelsModalHeaderView', ->

  { Simulate
    createRenderer
    renderIntoDocument
    scryRenderedDOMComponentsWithClass } = TestUtils


  describe '::render', ->

    it 'checks rendered header and its children props', ->

      shallowRenderer = createRenderer()
      shallowRenderer.render(<Header />)

      header = shallowRenderer.getRenderOutput()
      { children } = header.props

      expect(header.type).toEqual 'div'
      expect(children.length).toEqual 2
      expect(children[0].props.children).toEqual 'Channels'
      expect(children[0].props.className).toEqual 'ChannelList-title'


    it 'checks rendered search input classname, length and placeholder properties', ->

      header = renderIntoDocument(<Header />)
      input  = header.refs.ChannelSearchInput
      inputs = scryRenderedDOMComponentsWithClass header, 'ChannelList-searchInput'

      expect(inputs.length).toEqual 1
      expect(input.className).toEqual 'ChannelList-searchInput'
      expect(input.placeholder).toEqual 'Search'


  describe '::onChange', ->

    it 'should call onChange method', ->

      onChange = expect.createSpy()
      header   = renderIntoDocument(<Header onSearchInputChange={onChange}/>)
      input    = header.refs.ChannelSearchInput

      TestUtils.Simulate.change input

      expect(onChange).toHaveBeenCalled()

      expect.restoreSpies()

