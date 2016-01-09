kd                 = require 'kd'
React              = require 'kd-react'
expect             = require 'expect'
Modal              = require './index'
ModalView          = require './view'
ReactDOM           = require 'react-dom'
TestUtils          = require 'react-addons-test-utils'
mock               = require '../../../../mocks/mockingjay'
toImmutable        = require 'app/util/toImmutable'
expectCorrectRoute = require 'activity/test/helpers/expectCorrectRoute'


describe 'BrowsePrivateChannelsModal', ->

  { createRenderer
    renderIntoDocument
    scryRenderedDOMComponentsWithClass } = TestUtils

  it 'should render BrowsePrivateChannelsModal-Container with methods', ->

    shallowRenderer = createRenderer()
    shallowRenderer.render(<Modal.Container isOpen={yes}/>)

    modal = shallowRenderer.getRenderOutput()

    expect(modal.props.isOpen).toBeTruthy()
    expect(typeof modal.props.onClose).toEqual 'function'
    expect(typeof modal.props.onItemClick).toEqual 'function'


  it 'renders BrowsePrivateChannelsModal-View with PrivateChannelListModal and ChannelList-Modal classNames', ->

    shallowRenderer = createRenderer()
    shallowRenderer.render(<ModalView isOpen={yes}/>)

    view = shallowRenderer.getRenderOutput()

    expect(view.props.className).toContain 'PrivateChannelListModal'
    expect(view.props.className).toContain 'ChannelList-Modal'


  it 'checks rendered BrowsePrivateChannelsModal-View type and its child component props', ->

    shallowRenderer = createRenderer()
    shallowRenderer.render(<ModalView isOpen={yes}/>)

    view = shallowRenderer.getRenderOutput()
    { children } = view.props

    expect(children.props.threads).toExist()
    expect(children.props.title).toEqual 'Other Messages:'
    expect(children.props.searchProp).toEqual 'name'
    expect(children.props.onThresholdAction).toEqual 'loadFollowedPrivateChannels'
    expect(children.props.onItemClick).toExist()
    expect(typeof children.props.onThresholdAction).toEqual 'string'
    expect(typeof children.props.itemComponent).toEqual 'function'


  it 'should render BrowsePrivateChannelsModal-Container and checks onItemClick method of modal', ->

    modal = renderIntoDocument(<Modal.Container isOpen={no}/>)

    expect(modal.skipCloseHandling).toBeFalsy()
    expect(modal.onItemClick()).toBeTruthy()
    expect(modal.skipCloseHandling).toBeTruthy()


  it 'should not render BrowsePrivateChannelsModal-View to the DOM', ->

    view  = renderIntoDocument(<ModalView isOpen={no}/>)
    views = scryRenderedDOMComponentsWithClass view, 'PrivateChannelListModal'

    expect(view.refs.SidebarModalList).toNotExist()
    expect(view.props.isOpen).toBeFalsy()
    expect(views.length).toEqual 0


  it 'should call router.handleRoute method with public route parameter', ->

    expectCorrectRoute Modal, 'koding-dummy-channel', 'topic', "/Channels/koding-dummy-channel"


  it 'should call router.handleRoute method with private route parameter', ->

    expectCorrectRoute Modal, 'koding-12345', 'privatemessage', "/Messages/koding-12345"

