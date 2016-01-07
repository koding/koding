React                      = require 'kd-react'
ReactDOM                   = require 'react-dom'
expect                     = require 'expect'
TestUtils                  = require 'react-addons-test-utils'
BrowsePrivateChannelsModal = require '../browseprivatechannelsmodal'

describe 'BrowsePrivateChannelsModal', ->

  { createRenderer
    renderIntoDocument
    scryRenderedDOMComponentsWithClass } = TestUtils


  it 'renders BrowsePrivateChannelsModal with PrivateChannelListModal and ChannelList-Modal classNames', ->

    shallowRenderer = createRenderer()
    shallowRenderer.render(<BrowsePrivateChannelsModal isOpen={yes}/>)

    modal = shallowRenderer.getRenderOutput()

    expect(modal.props.isOpen).toBeTruthy()
    expect(modal.props.className).toContain 'PrivateChannelListModal'
    expect(modal.props.className).toContain 'ChannelList-Modal'


  it 'checks rendered modal type and its child component props', ->

    shallowRenderer = createRenderer()
    shallowRenderer.render(<BrowsePrivateChannelsModal isOpen={yes}/>)

    modal = shallowRenderer.getRenderOutput()
    { children } = modal.props

    expect(modal.type.name).toEqual 'Modal'
    expect(children.type.name).toEqual 'SidebarModalList'
    expect(children.props.threads).toExist()
    expect(children.props.title).toEqual 'Other Messages:'
    expect(children.props.searchProp).toEqual 'name'
    expect(children.props.onThresholdAction).toEqual 'loadFollowedPrivateChannels'
    expect(children.props.onItemClick).toExist()
    expect(children.props.onItemClick()).toBeTruthy()
    expect(typeof children.props.onThresholdAction).toEqual 'string'
    expect(typeof children.props.itemComponent).toEqual 'function'


  it 'renders BrowsePrivateChannelsModal and checks onItemClick method of modal', ->

    shallowRenderer = createRenderer()
    shallowRenderer.render(<BrowsePrivateChannelsModal isOpen={yes}/>)

    modal = shallowRenderer.getRenderOutput()
    { children } = modal.props

    expect(modal.props.onClose()).toEqual(undefined)
    expect(children.props.onItemClick()).toBeTruthy()
    expect(modal.props.onClose()).toBeFalsy()


  it 'does not render BrowsePrivateChannelsModal to the DOM and checks dom node existance', ->

    modal  = renderIntoDocument(<BrowsePrivateChannelsModal isOpen={no}/>)
    modals = scryRenderedDOMComponentsWithClass modal, 'PrivateChannelListModal'

    expect(modal.refs.SidebarModalList).toNotExist()
    expect(modal.props.isOpen).toBeFalsy()
    expect(modals.length).toEqual 0


