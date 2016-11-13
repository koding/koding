$ = require 'jquery'

# It is important that you should restore your current state,
# after each test. If not, you will break the sync testing.
describe 'SidebarMenu', ->
  before ->
    $('.team-name.no-logo').click() #show dropdown

  after ->
    $('.team-name.no-logo').click() #hide dropdown

  it 'should open on team click', ->
    sidebar = $('.kdview.kdcontextmenu.SidebarMenu')
    should(sidebar).exist
