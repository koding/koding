
do ->
  
  appView.addSubView a = new KDCustomHTMLView
    partial: "<marquee><img src='http://sinan.beta.koding.com/app-icons/donkey.jpg'/></marquee>"
  
  appView.addSubView b = new KDCustomHTMLView
    partial: "<marquee><h1>I call this an app!</h1></marquee>"

  appView.$().css "background-color", "pink"

  b.$().css
    backgroundColor: "red"
    color: "white"
