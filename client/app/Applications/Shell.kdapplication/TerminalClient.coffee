class TerminalClient

  constructor:(options)->
    @view = options.view
    @handler = options.handler
    @view.getDomElement().css("overflow","hidden").css("border","1 solid red");
    @diffScriptParser = new DiffScript
    @kb_buf = ''

  setHandler:(@handler)->
  reset:(size)->
  setError:(msg)->
    if msg? then @view.updatePartial msg,".cursor"

  resize:(size)->

  write:(data)->
    screen = data # @diffScriptParser.dispatch data
    # console.log "screen is now:",screen
    @view.updatePartial screen
  keyPress: (ev) ->
    return yes if ev.which is 118 and (ev.metaKey or ev.ctrlKey)
    if (ev.ctrlKey and not ev.altKey) or (ev.which is 0) or (ev.keyCode is 8) or (ev.keyCode is 16)
      @key_ev_stop ev
      return no

    kc =
      if ev.keyCode     then ev.keyCode
      else if ev.which  then ev.which

    k = String.fromCharCode(kc)

    if ev.altKey and not ev.ctrlKey
      k = String.fromCharCode(27)+k

    @process_key k

    @key_ev_stop ev
    no

  keyDown: (ev) ->
    k = ''
    kc = ev.keyCode;

    return yes if ev.which is 86 and (ev.metaKey or ev.ctrlKey)

    if (kc==33) then k=@esc_seq("5~")  # PgUp
    else if (kc==34) then k=@esc_seq("6~")  # PgDn
    else if (kc==35) then k=@esc_seq("4~")  # End
    else if (kc==36) then k=@esc_seq("1~")  # Home
    else if (kc==37) then k=@esc_seq("D")   # Left
    else if (kc==38) then k=@esc_seq("A")   # Up
    else if (kc==39) then k=@esc_seq("C")   # Right
    else if (kc==40) then k=@esc_seq("B")   # Down
    else if (kc==45) then k=@esc_seq("2~")  # Ins
    else if (kc==46) then k=@esc_seq("3~")  # Del
    else if (kc==27) then k=String.fromCharCode(27) # Escape
    else if (kc==9)  then k=String.fromCharCode(9)  # Tab
    else if (kc==8)  then k=String.fromCharCode(8)  # Backspace
    else if (kc==112) then k=@esc_seq(if ev.shiftKey then "25~" else "[A")  # F1
    else if (kc==113) then k=@esc_seq(if ev.shiftKey then "26~" else "[B")  # F2
    else if (kc==114) then k=@esc_seq(if ev.shiftKey then "28~" else "[C")  # F3
    else if (kc==115) then k=@esc_seq(if ev.shiftKey then "29~" else "[D")  # F4
    else if (kc==116) then k=@esc_seq(if ev.shiftKey then "31~" else "[E")  # F5
    else if (kc==117) then k=@esc_seq(if ev.shiftKey then "32~" else "17~") # F6
    else if (kc==118) then k=@esc_seq(if ev.shiftKey then "33~" else "18~") # F7
    else if (kc==119) then k=@esc_seq(if ev.shiftKey then "34~" else "19~") # F8
    else if (kc==120) then k=@esc_seq("20~") # F9
    else if (kc==121) then k=@esc_seq("21~") # F10
    else if (kc==122) then k=@esc_seq("23~") # F11
    else if (kc==123) then k=@esc_seq("24~") # F12

    else
      if (!ev.ctrlKey || (ev.ctrlKey && ev.altKey) || (ev.keyCode==17))
        @key_ev_supress(ev)
        return

      if (ev.shiftKey)
        if (kc==50) then k=String.fromCharCode(0)
        else if (kc==54) then k=String.fromCharCode(30)
        else if (kc==94) then k=String.fromCharCode(30)  
        else if (kc==109) then k=String.fromCharCode(31)
        else
          @key_ev_supress(ev)
          return
      else
        if (kc>=65 && kc<=90) then k=String.fromCharCode(kc-64)
        else if (kc==219) then k=String.fromCharCode(27)
        else if (kc==220) then k=String.fromCharCode(28)
        else if (kc==221) then k=String.fromCharCode(29)
        else if (kc==190) then k=String.fromCharCode(30)
        else if (kc==32) then k=String.fromCharCode(0)
        else
          @key_ev_supress(ev)
          return

    @process_key(k)

    @key_ev_stop(ev)
    return false


  # keyDown: (ev) ->
  #   k = ''
  #   kc = ev.keyCode
  #   console.log "i am at TerminalClient::keyDown",ev,kc
  # 
  #   return yes if ev.which is 86 and (ev.metaKey or ev.ctrlKey)
  # 
  #   k = switch kc
  #     when 33   then @esc_seq "5~"  # PgUp
  #     when 34   then @esc_seq "6~"  # PgDn
  #     when 35   then @esc_seq "4~"  # End
  #     when 36   then @esc_seq "1~"  # Home
  #     when 37   then @esc_seq "D"   # Left
  #     when 38   then @esc_seq "A"   # Up
  #     when 39   then @esc_seq "C"   # Right
  #     when 40   then @esc_seq "B"   # Down
  #     when 45   then @esc_seq "2~"  # Ins
  #     when 46   then @esc_seq "3~"  # Del
  #     when 27   then String.fromCharCode 27 # Escape
  #     when 9    then String.fromCharCode 9  # Tab
  #     when 8    then String.fromCharCode 8  # Backspace
  #     when 112  then @esc_seq(if ev.shiftKey then "25~" else "[A")  # F1
  #     when 113  then @esc_seq(if ev.shiftKey then "26~" else "[B")  # F2
  #     when 114  then @esc_seq(if ev.shiftKey then "28~" else "[C")  # F3
  #     when 115  then @esc_seq(if ev.shiftKey then "29~" else "[D")  # F4
  #     when 116  then @esc_seq(if ev.shiftKey then "31~" else "[E")  # F5
  #     when 117  then @esc_seq(if ev.shiftKey then "32~" else "17~") # F6
  #     when 118  then @esc_seq(if ev.shiftKey then "33~" else "18~") # F7
  #     when 119  then @esc_seq(if ev.shiftKey then "34~" else "19~") # F8
  #     when 120  then @esc_seq "20~" # F9
  #     when 121  then @esc_seq "21~" # F10
  #     when 122  then @esc_seq "23~" # F11
  #     when 123  then @esc_seq "24~" # F12
  #     else
  #       if not ev.ctrlKey or (ev.ctrlKey and ev.altKey) or (ev.keyCode is 17)
  #         @key_ev_supress ev
  #         no
  # 
  #       if ev.shiftKey
  #         switch kc
  #           when 50   then String.fromCharCode 0
  #           when 54   then String.fromCharCode 30
  #           when 94   then String.fromCharCode 30  
  #           when 109  then String.fromCharCode 31
  #           else
  #             @key_ev_supress ev
  #             no
  #       else
  #         if kc>=65 && kc<=90
  #           kc=65
  #           for i in [0..135]
  #             console.log i,String.fromCharCode(i)
  #           String.fromCharCode(kc-64)
  #         else switch kc
  #           when 219  then String.fromCharCode 27
  #           when 220  then String.fromCharCode 28
  #           when 221  then String.fromCharCode 29
  #           when 190  then String.fromCharCode 30
  #           when 32   then String.fromCharCode 0
  #           else
  #             @key_ev_supress ev
  #             no
  #   console.log "k:",k
  #   @process_key k if k
  # 
  #   @key_ev_stop ev
  #   return no
  
  send: ->
    command = @kb_buf
    @kb_buf = ''
    @handler command

  esc_seq: (s) ->
    console.log s
    String.fromCharCode(27) + "[" + s
    

  process_key: (k) ->
    @kb_buf+=k
    @maybe_send()
  
  maybe_send: ->
    if @kb_buf isnt ''
      @send()
      

  key_ev_stop: (ev) ->
    ev.cancelBubble = yes
    if (ev.stopPropagation) then ev.stopPropagation()
    if (ev.preventDefault)  then ev.preventDefault()
    try
      ev.keyCode=0
    catch e
      no
      
  key_ev_supress: (ev) ->
    ev.cancelBubble = yes
    if (ev.stopPropagation) then ev.stopPropagation()
    

