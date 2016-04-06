kd             = require 'kd'
React          = require 'kd-react'
ReactDOM       = require 'react-dom'
expect         = require 'expect'
TestUtils      = require 'react-addons-test-utils'
TeamStacksList = require '../components/teamstackslist/'
mock           = require '../../../../mocks/mockingjay'
toImmutable    = require 'app/util/toImmutable'


describe 'TeamStacksList', ->

  { renderIntoDocument,
    findRenderedDOMComponentWithClass } = TestUtils


  describe '::render', ->

    it 'should render correct children', ->

      templates={}
      template = mock.getTeamStackTemplate()
      templates[template._id] = toImmutable template
      templates = toImmutable templates

      listitem = renderIntoDocument(<TeamStacksList.Container />)
      listitem.setState {templates}

      result = findRenderedDOMComponentWithClass listitem, 'StackTemplateItem'
      expect(result).toExist()


    it 'should render correct machine title', ->

      templates={}
      template = mock.getTeamStackTemplate()
      templates[template._id] = toImmutable template
      templates = toImmutable templates

      listitem = renderIntoDocument(<TeamStacksList.Container />)
      listitem.setState {templates}

      result = findRenderedDOMComponentWithClass listitem, 'StackTemplateItem-label'
      expect(result.innerHTML).toEqual template.title