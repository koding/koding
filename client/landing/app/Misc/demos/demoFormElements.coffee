page_demoFormElements = (parentView)->

  parentView.addSubView header = new KDHeaderView type : "big", title : "KD Form Elements Demo"
  #CONTAINER 1
  container1 = new KDView
    cssClass : "generic-content-box"
  parentView.addSubView container1

  container1.addSubView container1Header = new KDHeaderView type : "medium", title : "KD Buttons"

  styles = [
    "clean-gray","clean-red","cupid-green","cupid-blue","blue-pill"
    "dribbble","slick-black","thoughtbot","blue-candy","purple-candy"
    "shiny-blue","small-blue","skip","minimal","small-gray","transparent"
  ]
  for style in styles
    button = new KDButtonView
      title : style
      style : style
      callback    : ()->
        new KDNotificationView
          title   : "Button clicked."
          duration  : 400
    container1.addSubView button
    


  #CONTAINER 2
  container2 = new KDView
    cssClass : "generic-content-box"
  parentView.addSubView container2

  container2.addSubView container2Header = new KDHeaderView type : "medium", title : "KD Input Fields & Labels"

  label = new KDLabelView
    title : "This is a KDLabelView"

  labelSelect = new KDLabelView
    title : "KDLabelView of selectbox"

  selectSample = new KDInputView
    type          : "select"
    label         : labelSelect
    defaultValue  : "car"
    selectOptions : [
      {
        title : "Some Option"
        value : "car"
      },{
        title : "Another Option"
        value : "cur"
      },{
        title : "Some other option"
        value : "cir"
      }
    ]

  container2.addSubView label

  container2.addSubView labelSelect
  container2.addSubView selectSample

