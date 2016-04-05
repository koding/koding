kd                    = require 'kd'
React                 = require 'kd-react'
ReactDOM              = require 'react-dom'
expect                = require 'expect'
TestUtils             = require 'react-addons-test-utils'
PrivateStacksList     = require '../components/privatestackslist/'
mock                  = require '../../../../mocks/mockingjay'
toImmutable           = require 'app/util/toImmutable'


describe 'PrivateStacksList', ->

 { renderIntoDocument,
   findRenderedDOMComponentWithClass } = TestUtils


 describe '::render', ->

   it 'should render correct children', ->

    templates={}


    listitem = renderIntoDocument(<PrivateStacksList.Container />)
    listitem.setState {templates}

    result = findRenderedDOMComponentWithClass listitem, 'StackTemplateItem'
    expect(result).toExist()