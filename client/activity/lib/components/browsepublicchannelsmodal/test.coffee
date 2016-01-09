React              = require 'kd-react'
ReactDOM           = require 'react-dom'
expect             = require 'expect'
Modal              = require './index'
ModalView          = require './view'
TabView            = require './tabview'
Header             = require './header'
TestUtils          = require 'react-addons-test-utils'
ActivityFlux       = require 'activity/flux'
Tabs               = require 'activity/constants/sidebarpublicchannelstabs'
expectCorrectRoute = require 'activity/test/helpers/expectCorrectRoute'


describe 'BrowsePublicChannelsModal', ->

  { Simulate
    createRenderer
    renderIntoDocument
    getItemFromContainer
    findAllInRenderedTree
    scryRenderedDOMComponentsWithClass } = TestUtils

  { channel } = ActivityFlux.actions

  it 'renders BrowsePublicChannelsModal with PublicChannelListModal and ChannelList-Modal classNames', ->

    shallowRenderer = createRenderer()
    shallowRenderer.render(<Modal />)

    modal = shallowRenderer.getRenderOutput()

    expect(modal.props.isOpen).toBeTruthy()
    expect(modal.props.className).toContain 'PublicChannelListModal'
    expect(modal.props.className).toContain 'ChannelList-Modal'


  it 'checks rendered modal child component className', ->

    shallowRenderer = createRenderer()
    shallowRenderer.render(<Modal />)

    modal = shallowRenderer.getRenderOutput()
    { children } = modal.props

    expect(children.props.className).toEqual 'ChannelListWrapper'
    expect(children.props.children.length).toEqual 3


  it 'checks rendered modal child component DOM node className', ->

    modal = renderIntoDocument(<Modal isOpen={no}/>)
    node  = ReactDOM.findDOMNode modal

    expect(node.className).toEqual 'Modal-container'


  it 'should render modal-container and checks onItemClick method of modal', ->

    modal = renderIntoDocument(<Modal.Container isOpen={no}/>)

    expect(modal.skipCloseHandling).toBeFalsy()
    expect(modal.onItemClick()).toBeTruthy()
    expect(modal.skipCloseHandling).toBeTruthy()


  it 'should call channel actions loadChannels and setSidebarPublicChannelsTab methods', ->

    modal           = renderIntoDocument(<Modal.Container isOpen={no}/>)
    channelsTabSpy  = expect.spyOn channel, 'setSidebarPublicChannelsTab'
    loadChannelsSpy = expect.spyOn channel, 'loadChannels'

    modal.onOtherChannelsClick()

    expect(loadChannelsSpy).toHaveBeenCalled()
    expect(channelsTabSpy).toHaveBeenCalledWith Tabs.OtherChannels


  it 'should call channel actions loadFollowedPublicChannels and setSidebarPublicChannelsTab methods', ->

    modal                   = renderIntoDocument(<Modal.Container isOpen={no}/>)
    channelsTabSpy          = expect.spyOn channel, 'setSidebarPublicChannelsTab'
    loadFollowedChannelsSpy = expect.spyOn channel, 'loadFollowedPublicChannels'

    modal.onYourChannelsClick()

    expect(loadFollowedChannelsSpy).toHaveBeenCalled()
    expect(channelsTabSpy).toHaveBeenCalledWith Tabs.YourChannels


  it 'should call channel actions loadChannelsByQuery and setSidebarPublicChannelsQuery methods', ->

    modal                  = renderIntoDocument(<Modal.Container isOpen={no}/>)
    loadChannelsByQuerySpy = expect.spyOn channel, 'loadChannelsByQuery'
    publicChannelsQuerySpy = expect.spyOn channel, 'setSidebarPublicChannelsQuery'

    dummyValue = 'input-dummy-value'

    mockEvent =
      target:
        value: ''

    modal.onSearchInputChange mockEvent

    expect(loadChannelsByQuerySpy).toNotHaveBeenCalled()
    expect(publicChannelsQuerySpy).toHaveBeenCalledWith ''

    mockEvent.target.value = dummyValue

    modal.onSearchInputChange mockEvent

    expect(loadChannelsByQuerySpy).toHaveBeenCalledWith dummyValue
    expect(publicChannelsQuerySpy).toHaveBeenCalledWith dummyValue


  it 'should call modal-container onYourChannelsClick method', ->

    modal = renderIntoDocument(<Modal.Container isOpen={no}/>)
    spy   = expect.spyOn modal, 'onYourChannelsClick'

    modal.onTabChange Tabs.YourChannels

    expect(spy).toHaveBeenCalled()


  it 'should call modal-container onOtherChannelsClick method', ->

    modal = renderIntoDocument(<Modal.Container isOpen={no}/>)
    spy   = expect.spyOn modal, 'onOtherChannelsClick'

    modal.onTabChange Tabs.OtherChannels

    expect(spy).toHaveBeenCalled()


  it 'should call channel actions loadChannelsByQuery method', ->

    modal   = renderIntoDocument(<Modal.Container isOpen={no}/>)
    spy     = expect.spyOn channel, 'loadChannelsByQuery'
    query   = 'dummy-query'
    options = { key : 'dummy-value' }

    modal.setState { query }

    modal.onThresholdReached options

    expect(spy).toHaveBeenCalledWith 'dummy-query', options


  it 'should call channel actions loadFollowedPublicChannels method', ->

    modal   = renderIntoDocument(<Modal.Container isOpen={no}/>)
    spy     = expect.spyOn channel, 'loadFollowedPublicChannels'
    query   = 'dummy-query'
    options = { key : 'dummy-value' }

    modal.setState tab: Tabs.YourChannels

    modal.onThresholdReached options

    expect(spy).toHaveBeenCalledWith options


  it 'should call channel actions loadChannels method', ->

    modal   = renderIntoDocument(<Modal.Container isOpen={no}/>)
    spy     = expect.spyOn channel, 'loadChannels'
    options = { key : 'dummy-value' }

    modal.setState tab: Tabs.OtherChannels

    modal.onThresholdReached options

    expect(spy).toHaveBeenCalledWith options


  it 'should call router.handleRoute method with public route parameter', ->

    expectCorrectRoute Modal, 'koding-dummy-channel', 'topic', "/Channels/koding-dummy-channel"


  it 'should call router.handleRoute method with private route parameter', ->

    expectCorrectRoute Modal, 'koding-12345', 'privatemessage', "/Messages/koding-12345"


  it 'checks rendered modal props type', ->

    modal = renderIntoDocument(<ModalView isOpen={no}/>)

    expect(typeof modal.props.query).toEqual 'string'
    expect(typeof modal.props.className).toEqual 'string'
    expect(typeof modal.props.onClose).toEqual 'function'
    expect(typeof modal.props.onTabChange).toEqual 'function'
    expect(typeof modal.props.onItemClick).toEqual 'function'
    expect(typeof modal.props.onThresholdReached).toEqual 'function'
    expect(typeof modal.props.onSearchInputChange).toEqual 'function'
    expect(typeof modal.props.isOpen).toEqual 'boolean'
    expect(typeof modal.props.isSearchActive).toEqual 'boolean'


  it 'checks rendered tabView and its children props', ->

    shallowRenderer = createRenderer()
    shallowRenderer.render(<TabView />)

    tabView = shallowRenderer.getRenderOutput()
    { children } = tabView.props

    expect(tabView.type).toEqual 'div'
    expect(tabView.props.className).toEqual 'ChannelList-tabs'
    expect(children.length).toEqual 3
    expect(children[0].ref).toEqual 'yourChannels'
    expect(children[1].ref).toEqual 'otherChannels'
    expect(children[0].props.children).toEqual 'Your Channels'
    expect(children[1].props.children).toEqual 'Other Channels'
    expect(children[0].props.className).toEqual 'ChannelList-tab'
    expect(children[1].props.className).toEqual 'ChannelList-tab'
    expect(children[2].props.className).toEqual 'clearfix'


  it 'should call onChange method of tabview', ->

    onChange      = expect.createSpy()
    tabView       = renderIntoDocument(<TabView onChange={onChange}/>)
    yourChannels  = tabView.refs.yourChannels
    otherChannels = tabView.refs.otherChannels

    TestUtils.Simulate.click yourChannels

    expect(onChange).toHaveBeenCalledWith(Tabs.YourChannels)

    TestUtils.Simulate.click otherChannels

    expect(onChange).toHaveBeenCalledWith(Tabs.OtherChannels)


  it 'checks rendered header and its children props', ->

    shallowRenderer = createRenderer()
    shallowRenderer.render(<Header />)

    header = shallowRenderer.getRenderOutput()
    { children } = header.props

    expect(header.type).toEqual 'div'
    expect(children.length).toEqual 2
    expect(children[0].props.children).toEqual 'Channels'
    expect(children[0].props.className).toEqual 'ChannelList-title'


  it 'checks rendered search input properties', ->

    header = renderIntoDocument(<Header />)
    input  = header.refs.ChannelSearchInput
    inputs = scryRenderedDOMComponentsWithClass header, 'ChannelList-searchInput'

    expect(inputs.length).toEqual 1
    expect(input.className).toEqual 'ChannelList-searchInput'
    expect(input.placeholder).toEqual 'Search'


  it 'checks onSearchInputChange method of header and should call onChange function', ->

    onChange = expect.createSpy()
    header   = renderIntoDocument(<Header onSearchInputChange={onChange}/>)
    input    = header.refs.ChannelSearchInput

    TestUtils.Simulate.change input

    expect(onChange).toHaveBeenCalled()

