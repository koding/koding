class IntroView extends JView

  viewAppended:->

    @addSubView @slider = new Slider
      directions : Slider.directions.leftToRight

    @slider.addPage page1 = new Page
      content  : 'Page 1'
    page1.setCss backgroundColor : '#518e2f'

    @slider.addPage page2 = new Page
      content  : 'Page 2'
    page2.setCss backgroundColor : '#b6a43c'

    @slider.addSubPage page10 = new Page
      content  : 'Subpage #1 of Page 2'
    page10.setCss backgroundColor : '#ff9200'

    @slider.addSubPage page11 = new Page
      content  : 'Subpage #2 of Page 2'
    page11.setCss backgroundColor : '#fff200'

    @slider.addSubPage page12 = new Page
      content  : 'Subpage #3 of Page 2'
    page12.setCss backgroundColor : '#ff0900'

    @slider.addPage page3 = new Page
      content  : 'Page 3'
    page3.setCss backgroundColor : '#309063'

    @slider.addSubPage page13 = new Page
      content  : 'Subpage #1 of Page 3'
    page13.setCss backgroundColor : '#0ff900'

    @addSubView nextButton = new KDButtonView
      cssClass : 'next'
      title    : 'Next Page'
      callback : => @slider.nextPage()

    nextButton.setStyle
      position : 'absolute'
      right    : '10px'
      bottom   : '10px'

    @addSubView prevButton = new KDButtonView
      cssClass : 'prev'
      title    : 'Previous Page'
      callback : => @slider.previousPage()

    prevButton.setStyle
      position : 'absolute'
      left     : '10px'
      bottom   : '10px'

    @addSubView previousSubPageButton = new KDButtonView
      cssClass : 'Down'
      title    : 'Previous SubPage'
      callback : => @slider.previousSubPage()

    previousSubPageButton.setStyle
      position : 'absolute'
      left     : '200px'
      bottom   : '10px'

    @addSubView nextSubPageButton = new KDButtonView
      cssClass : 'up'
      title    : 'Next SubPage'
      callback : => @slider.nextSubPage()

    nextSubPageButton.setStyle
      position : 'absolute'
      right    : '200px'
      bottom   : '10px'

appView = new IntroView
appView.setStyle
  position : 'absolute'
  top      : 0

appView.appendToDomBody()