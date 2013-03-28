do ->
    
    appView.setPartial "My very own app"
    appView.$().css
        backgroundColor : "red"
        color           : "white"