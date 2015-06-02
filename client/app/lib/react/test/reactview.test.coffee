kd         = require 'kd'
{ expect } = require 'chai'
React      = require 'react/addons'

ReactView = require '../reactview'

renderIntoDocument = (view) ->
  div = document.createElement 'div'
  div.appendChild view.getElement()
  view.emit 'viewAppended'

  return view

findRenderedDOMWithClassName = (view, className) ->

  view.getElement().querySelector ".#{className}"


describe 'ReactView', ->

  it 'works', ->

    expect(new ReactView).to.be.ok


  it 'renders dom element with react', ->

    class FooReactView extends ReactView

      renderReact: ->
        <div className="hello-world">Hello World</div>

    foo = renderIntoDocument(new FooReactView)

    helloWorld = findRenderedDOMWithClassName foo, 'hello-world'

    expect(helloWorld.textContent).to.equal 'Hello World'

