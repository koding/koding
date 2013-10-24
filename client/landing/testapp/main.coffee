# A bouncing ball example by Gokmen Goksel
# @gokmen - http://gokmen.koding.com

class MainView extends JView

  constructor:->
    super

    @ball = new KDView
      cssClass : 'ball'

    @_width   = 400
    @_height  = 300

    @.$().css width : @_width
    @.$().css height: @_height

    @_x = @x = @_y = @y = 1

    @updateBallPosition()

  updateBallPosition:->

    @x += @_x
    @y += @_y

    @_x = -1 if @x >= @_width - 50
    @_x =  1 if @x == 0

    @_y = -1 if @y >= @_height - 50
    @_y =  1 if @y == 0

    @ball.$().css top: @y
    @ball.$().css left:@x

    setTimeout =>
      @updateBallPosition()
    , 5

  pistachio:->
    """
    {{> this.ball}}
    """

appView = new MainView
  cssClass: "bounce"

KDView.appendToDOMBody appView