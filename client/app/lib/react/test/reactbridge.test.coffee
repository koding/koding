kd            = require 'kd'
React         = require 'react/addons'
{ expect }    = require 'chai'
{ TestUtils } = React.addons

ReactBridge = require '../reactbridge'

describe 'ReactBridge', ->

  it 'requires a dispatcher to work', ->

    bridge = TestUtils.renderIntoDocument(
      <ReactBridge dispatcher={new kd.Object} />
    )

    expect(bridge).to.be.ok

    createBridgeWithoutDispatcher = ->
      bridge = TestUtils.renderIntoDocument(
        <ReactBridge />
      )

    expect(createBridgeWithoutDispatcher).to.throw /requires a dispatcher/


  describe '#constructor', ->

    it 'renders nothing if nothing is passed', ->

      container = renderBridge dispatcher: new kd.Object

      expect(container.getDOMNode().childElementCount).to.equal 0


    it 'renders given component', ->

      container = renderBridge
        dispatcher: new kd.Object
        component: <div className="foo">Hello World</div>

      element = container.getDOMNode()

      expect(element.childElementCount).to.equal 1
      expect(element.textContent).to.equal 'Hello World'


  describe 'bridge dispatcher', ->

    # since this class is designed to be used by a KDReactView,
    # it uses a dispatcher to communicate outside world.
    # That default dispatcher for now has limited api,
    # but a subclass of a KDBridgeComponent can implement extra
    # functionality, since KDReactView accepts a custom KDReactBridge
    # class through its options object.

    it 'uses dispatcher to set its component any time', ->

      # KDReactView will automatically create a dispatcher
      # and will save you from this boilerplate. In fact, KDReactBridge
      # is just an implementation detail to make arbitrary react components
      # to work inside KD Framework.
      mockDispatcher = new kd.Object

      component = <div>Hello World</div>
      container = renderBridge dispatcher: mockDispatcher, component: component

      element = container.getDOMNode()

      expect(element.textContent).to.equal 'Hello World'

      component = <div>Hello Changed World</div>

      mockDispatcher.emit 'SetComponent', component

      expect(container.getDOMNode().textContent).to.equal 'Hello Changed World'



renderBridge = (options) ->

  bridge = TestUtils.renderIntoDocument(
    <ReactBridge {...options} />
  )

  return TestUtils.findRenderedDOMComponentWithClass bridge, 'js-bridgeContainer'


