class FinderCalculatorItemView extends FinderItemView
  constructor: ->
    super cssClass: '', new File null,
      item : 
        path : "/"
        title : "fakefile"
   # fake data, ignore console errors for now
   # console errors fixed!!
    
  viewAppended: ->
    @setPartial @partial()

  partial:(data)->
    $ "<div class='finder-item folder-item clearfix'>
        <span class='iconfolder'></span>
        <span class='title'>Calculator</span>
      </div>
      <span class='chevron-arrow'></span>"
