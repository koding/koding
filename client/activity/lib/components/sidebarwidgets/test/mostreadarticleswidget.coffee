React                  = require 'kd-react'
expect                 = require 'expect'
TestUtils              = require 'react-addons-test-utils'
MostReadArticlesWidget = require '../mostreadarticleswidget'

describe 'MostReadArticlesWidget', ->

  { renderIntoDocument
   findRenderedDOMComponentWithClass
   findRenderedDOMComponentWithTag
   scryRenderedDOMComponentsWithTag } = TestUtils

  describe '::render', ->

    it 'should render widget and children with correct class name', ->

      mostreadarticleswidget = renderIntoDocument(<MostReadArticlesWidget />)

      div = findRenderedDOMComponentWithClass mostreadarticleswidget, 'MostReadArticlesWidget ActivitySidebar-widget'

      expect(div).toExist()


    arrayEqual = (a, b) ->
      a.length is b.length and a.every (elem, i) -> elem.props.children is b[i]


    it 'should render children with correct values', ->

      mostReadArticlesWidget = renderIntoDocument(<MostReadArticlesWidget />)

      h3        = findRenderedDOMComponentWithTag mostReadArticlesWidget, 'h3'
      archeries = scryRenderedDOMComponentsWithTag mostReadArticlesWidget, 'a'

      archValues = [
        'How to ssh into your VM?'
        'Using the Koding Package Manager'
        'What is Koding?'
        'Getting started with IDE Workspaces'
        'Changing your IDE and Terminal themes'
        'More guides on Koding University...'
      ]

      expect(arrayEqual archeries, archValues).toBeTruthy()