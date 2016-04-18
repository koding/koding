kd                 = require 'kd'
React              = require 'kd-react'
ReactDOM           = require 'react-dom'
expect             = require 'expect'
TeamTeammates      = require './view'
TestUtils          = require 'react-addons-test-utils'
toImmutable        = require 'app/util/toImmutable'
Encoder            = require 'htmlencode'
getters            = require 'app/flux/teams/getters'
mock               = require '../../../../../mocks/mockingjay'
immutable          = require 'immutable'

describe 'HomeTeamTeammates', ->
  
  { createRenderer, 
  renderIntoDocument,
  findRenderedDOMComponentWithClass,
  scryRenderedDOMComponentsWithClass } = TestUtils
  
  describe '::render', ->
    
    it 'should render search box', ->
      
      teamMates = renderIntoDocument <TeamTeammates />
      searchbox = findRenderedDOMComponentWithClass teamMates, 'search'
      expect(searchbox).toExist()
       
       
    it 'should render any row for members', ->
      
      teamMates = renderIntoDocument <TeamTeammates />
      membersListView = scryRenderedDOMComponentsWithClass teamMates, 'ListView-row'
      expect(membersListView.length).toEqual 0
      
    
    it 'should render with correct team members and their informations', ->
      
      members = mock.getTeamMembersWithRole()
      members = immutable.fromJS members
      
      teamMates = renderIntoDocument <TeamTeammates members={members}/>
      
      membersListView = scryRenderedDOMComponentsWithClass teamMates, 'ListView-row' #kdview kdlistview kdlistview-default
      
      expect(membersListView.length).toEqual members.size
      
    
    it 'should render with correct team member emails', ->
      
      members = mock.getTeamMembersWithRole()
      members = immutable.fromJS members
      
      teamMates = renderIntoDocument <TeamTeammates members={members}/>
      
      emails = scryRenderedDOMComponentsWithClass teamMates, 'email'
      emails = emails.map (email) -> email.innerHTML
      emails = emails.sort()
      
      memberEmails = members.toArray().map (member) -> member.getIn ['profile', 'email']
      
      memberEmails = memberEmails.sort()
      expect(emails).toEqual memberEmails