kd                 = require 'kd'
React              = require 'app/react'
ReactDOM           = require 'react-dom'
expect             = require 'expect'
TeamSettings       = require './index'
TestUtils          = require 'react-addons-test-utils'
toImmutable        = require 'app/util/toImmutable'
Encoder            = require 'htmlencode'
mock               = require '../../../../../mocks/mockingjay'
immutable          = require 'immutable'


describe 'HomeTeamSettings', ->

  { Simulate,
  createRenderer,
  renderIntoDocument,
  findRenderedDOMComponentWithClass,
  scryRenderedDOMComponentsWithTag } = TestUtils

  describe '::render', ->

    it 'should render with correct team name and team domain', ->

      team = immutable.fromJS mock.getTeam()

      teamSettings = renderIntoDocument(<TeamSettings.Container />)
      teamSettings.setState {team}

      teamName = findRenderedDOMComponentWithClass teamSettings, 'kdinput text js-teamName'

      actualTeamName = Encoder.htmlDecode team.get 'title' ? ''

      expect(teamName.value).toEqual actualTeamName


    it 'should render with correct team domain', ->

      team = immutable.fromJS mock.getTeam()

      teamSettings = renderIntoDocument(<TeamSettings.Container />)
      teamSettings.setState {team}

      teamDomain = findRenderedDOMComponentWithClass teamSettings, 'kdinput text js-teamDomain'

      actualTeamDomain = "#{Encoder.htmlDecode team.get 'slug'}.koding.com" ? ''

      expect(teamDomain.value).toEqual actualTeamDomain


      # split to to 2
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



    # split into 2
    it 'should render correct team logo path', ->

      team = mock.getTeam()
      team = immutable.fromJS team

      teamSettings = renderIntoDocument(<TeamSettings.Container />)
      teamSettings.setState {team}

      teamLogo = findRenderedDOMComponentWithClass teamSettings, 'teamLogo'
      expect(teamLogo.src).toContain '/a/images/logos/default_team_logo.svg'

      team = team.setIn ['customize', 'logo'], 'team_logo_path'
      teamSettings.setState {team}

      teamLogo = findRenderedDOMComponentWithClass teamSettings, 'teamLogo'
      expect(teamLogo.src).toContain 'team_logo_path'
