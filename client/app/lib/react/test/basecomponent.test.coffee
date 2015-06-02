React         = require 'react/addons'
{ expect }    = require 'chai'
{ TestUtils } = React.addons

KDReactComponent = require '../basecomponent'

describe 'KDReactComponent', ->

  class FooComponent extends KDReactComponent
    render: -> <div {...@props} />

  it 'works', ->

    expect(<FooComponent />).to.be.ok


  it 'has KDObject::bound abilities', ->

    flag = no

    class BarComponent extends KDReactComponent
      constructor: (props) ->
        super props
        # this will prove that bound method works for
        # click handlers as it should. We are gonna assign
        # this instance variable to flag, and will test if flag has
        # this value.
        @instanceBoolean = yes

      onClick: -> flag = @instanceBoolean
      render: -> <div onClick={@bound 'onClick'} />

    flag = no
    onClick = (e) -> flag = yes

    component = TestUtils.renderIntoDocument(
      <BarComponent onClick={onClick} />
    )

    element = TestUtils.findRenderedDOMComponentWithTag component, 'div'

    TestUtils.Simulate.click element

    expect(flag).to.equal yes


