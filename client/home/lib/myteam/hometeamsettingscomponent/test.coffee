kd                 = require 'kd'
React              = require 'kd-react'
ReactDOM           = require 'react-dom'
expect             = require 'expect'
TeamSettings       = require './index'
TestUtils          = require 'react-addons-test-utils'
toImmutable        = require 'app/util/toImmutable'
Encoder            = require 'htmlencode'
mock               = require '../../../../mocks/mockingjay'
immutable          = require 'immutable'


describe 'HomeTeamSettings', ->
  
  { Simulate,
  createRenderer, 
  renderIntoDocument,
  findRenderedDOMComponentWithClass,
  scryRenderedDOMComponentsWithClass,
  scryRenderedDOMComponentsWithTag } = TestUtils
  
  describe '::render', ->
    
    it 'should render with correct team name and team domain', ->
      
      team = mock.getTeam()
      team = immutable.fromJS team
      
      
      teamSettings = renderIntoDocument(<TeamSettings.Container />)
      teamSettings.setState {team}
      
      teamDomain = teamSettings.refs.view.refs.teamDomain.value
      teamName = teamSettings.refs.view.refs.teamName.value
      
      actualTeamDomain = "#{Encoder.htmlDecode team.get 'slug'}.koding.com" ? ''
      actualTeamName = Encoder.htmlDecode team.get 'title' ? ''
      
      expect(teamDomain).toEqual actualTeamDomain
      expect(teamName).toEqual actualTeamName
      
      
    it 'should render correct buttons', ->
      
      { groupsController } = kd.singletons
      
      canEdit = groupsController.canEditGroup()

      team = groupsController.getCurrentGroup()
      team = toImmutable team
      
      teamSettings = renderIntoDocument(<TeamSettings.Container />)
      teamSettings.setState {team}
      
      buttons = scryRenderedDOMComponentsWithTag teamSettings, 'span'
      
      expect(buttons.length).toEqual 4  if canEdit
      
      expect(buttons.length).toEqual 3  unless canEdit
      
      
  
    it 'should render correct team logo path', ->
      
      team = mock.getTeam()
      team = immutable.fromJS team
      
      teamSettings = renderIntoDocument(<TeamSettings.Container />)
      teamSettings.setState {team}
      
      teamLogo = findRenderedDOMComponentWithClass teamSettings, 'teamLogo'
      expect(teamLogo.src).toContain '/a/images/logos/sidebar_footer_logo.svg'
      
      team = team.setIn ['customize', 'logo'], 'team_logo_path'
      teamSettings.setState {team}
      
      teamLogo = findRenderedDOMComponentWithClass teamSettings, 'teamLogo'
      expect(teamLogo.src).toContain 'team_logo_path'
      
      
      
      
      