****  mass:werk termlib.js - JS-WebTerminal Object v1.57  ****

  (c) Norbert Landsteiner 2003-2010
  mass:werk - media environments
  <http://www.masswerk.at>




### COMPATIBILITY WARNING ###

Dropped support of Netscape 4 (layers) with version 1.5!
Netscape 4 is now outdated for more than 10 years. Any further support of this browser
would be of academic nature. As a benefit this step allows us to include the socket
extension in the main library, so there are no additional files to load anymore.


For the first time there is a backward compatibility issue from version 1.3 to version 1.4:
The following applies to the style vector for the `type()' method while using colors:

   while with version 1.3 a color was encoded using the color code times 16 (0xf), e.g.:
   
      myTerm.type( 'This is red.', 2*16 );
   
   this changed with version 1.4 to the color code times 256 (0xff), e.g.:
   
      myTerm.type( 'This is red.', 2*256 );


All other style encodings or color API remain unchanged.
Since this feature was only introduced in version 1.3 and there are no known applications
that would use a statement like the above (since you would usually use the `write()' method
for complex output), this seems to be good bargain for some codes for custom styles.
C.f.: sect 7.5 "TermGlobals.assignStyle()"


### Mac OS X Dead-Keys ###

(Dead-keys: combinations of accents and characters that are built by two consecutively pressed keys.)
Mac OS X 10.5 and later doesn't fire a keyboard event for dead keys anymore.
It's possible to fix this for Safari by a custom dead keys emulation, but not for Chrome or Firefox.
"termlib.js" provides automatic translations of common dead-keys for Safari in German (de-de).
In case you would need dead-keys for another language, please contact me via http://www.masswerk.at/.



Contents:

   1  About
   2  Creating a new Terminal Instance
      2.1 Configuration Values
   3  Using the Terminal
      3.1  The Default Handler
      3.2  Input Modes
           3.2.1  Normal Line Input (Command Line Mode)
                  3.2.1.2 Special Keys (ctrlHandler)
           3.2.2  Raw Mode
           3.2.3  Character Mode
      3.3  Other Handlers
           3.3.1  initHandler
           3.3.2  exitHandler
      3.4  Flags for Behaviour Control
   4  Output Methods
           4.1  Terminal.type()
           4.2  Terminal.write()
           4.3  Terminal.typeAt()
           4.4  Terminal.setChar()
           4.5  Terminal.newLine()
           4.6  Terminal.clear()
           4.7  Terminal.statusLine()
           4.8  Terminal.printRowFromString()
           4.9  Terminal.redraw()
           4.10 Using Color
           4.11 Text Wrap - Terminal.wrapOn(), Terminal.wrapOff()
           4.12 ANSI Support
   5  Cursor Methods and Editing
           5.1  Terminal.cursorOn()
           5.2  Terminal.cursorOff()
           5.3  Terminal.cursorSet()
           5.4  Terminal.cursorLeft()
           5.5  Terminal.cursorRight()
           5.6  Terminal.backspace()
           5.7  Terminal.fwdDelete()
           5.8  Terminal.isPrintable()
   6  Other Methods of the Terminal Object
           6.1  Terminal.prompt()
           6.2  Terminal.reset()
           6.3  Terminal.open()
           6.4  Terminal.close()
           6.5  Terminal.focus()
           6.6  Terminal.moveTo()
           6.7  Terminal.resizeTo()
           6.8  Terminal.getDimensions()
           6.9  Terminal.rebuild()
           6.10 Terminal.backupScreen();
           6.11 Terminal.restoreScreen();
           6.12 Terminal.swapBackup();
   7  Global Static Methods (TermGlobals)
           7.1  TermGlobals.setFocus()
           7.2  TermGlobals.keylock (Global Locking Flag)
           7.3  TermGlobals Text Methods
                7.3.1  TermGlobals.normalize()
                7.3.2  TermGlobals.fillLeft()
                7.3.3  TermGlobals.center()
                7.3.4  TermGlobals.stringReplace()
           7.4  TermGlobals Import Methods
                7.4.1  TermGlobals.insertText()
                7.4.2  TermGlobals.importEachLine()
                7.4.3  TermGlobals.importMultiLine()
           7.5  TermGlobals.assignStyle()
   8  Localization
   9  The Socket Extension (Remote Communication)
           9.1  A First Example
           9.2  The send() API
           9.3  Global Config Settings
           9.4  The Callback (Response Handling)
           9.5  Error Codes
           9.6  Note on Compatibly / Browser Requirements
           9.7  termlib_socket.js Version History
  10  Cross Browser Functions
  11  Architecture, Internals
      11.1  Global Entities
      11.2  I/O Architecture
      11.3  Compatibility
  12  History
  13  Example for a Command Line Parser
  14  License
  15  Disclaimer
  16  Donations
  17  References




1  About

The Terminal library "termlib.js" provides an object oriented constructor and control
methods for a terminal-like DHTML interface.

"termlib.js" features direct keyboard input and powerful output methods for multiple
instances of the `Terminal' object (including focus control).
"termlib.js" also comprises methods for a transparent handling of client-server com-
munications via XMLHttpRequests (see sect. 9 "The Socket Extension").

The library was written with the aim of simple usage and a maximum of compatibility with
minimal foot print in the global namespace.


A simple example:

  // creating a terminal and using it

  var term = new Terminal( {handler: termHandler} );
  term.open();

  function termHandler() {
    var line = this.lineBuffer;
    this.newLine();
    if (line == "help") {
      this.write(helpPage)
    }
    else if (line == "exit") {
      this.close();
      return;
    }
    else if (line != "") {
      this.write("You typed: "+line);
    }
    this.prompt();
  }

  var helpPage = [
    "This is the monstrous help page for my groovy terminal.",
    "Commands available:",
    "   help ... print this monstrous help page",
    "   exit ... leave this groovy terminal",
    " ",
    "Have fun!"
  ];


You should provide CSS font definitions for the classes ".term" (normal video) and
".termReverse" (reverse video) in a monospaced font.
A sample stylesheet "term_styles.css" comes with this library.

See the sample application "multiterm_test.html" for a demo of multiple terminals.

v.1.01: If you configure to use another font class (see 2.1 Configuration Values),
        you must provide a subclass ".termReverse" for reversed video.

        p.e.: .myFontClass .termReverse {
                /* your definitions for reverse video here */
              }
        
        With the addition of `conf.fontClass' you can now create multiple
        instances with independend appearences.




2   Creating a new Terminal Instance

Use the `new' constructor to create a new instance of the Terminal object. You will want
to supply a configuration object as an argument to the constructor. If the `new'
constructor is called without an object as its first argument, default values are used.

p.e.:

  // creating a new instance of Terminal

  var conf= {
    x: 100,
    y: 100,
    cols: 80,
    rows: 24
  }

  var term = new Term(conf);
  term.open();

`Terminal.open()' initializes the terminal and makes it visible to the user.
This is handled in by separate method to allow the re-initilization of instances
previously closed.

NOTE:
The division or HTML-element that holds the terminal must be present when calling
`Terminal.open()'. So you must not call this method from the header of a HTML-document at
compile time.



2.1 Configuration Values

Set any of these values in your configuration object to override:

  
  LABEL                     DEFAULT VALUE    COMMENT
  
  x                                   100    terminal's position x in px
  y                                   100    terminal's position y in px
  divDiv                        'termDiv'    id of terminals CSS division
  bgColor                       '#181818'    background color (HTML hex value)
  frameColor                    '#555555'    frame color (HTML hex value)
  frameWidth                            1    frame border width in px
  fontClass                        'term'    class name of CSS font definition to use
  cols                                 80    number of cols per row
  rows                                 24    number of rows
  rowHeight                            15    a row's line-height in px
  blinkDelay                          500    delay for cursor blinking in milliseconds
  crsrBlinkMode                     false    true for blinking cursor
  crsrBlockMode                      true    true for block-cursor else underscore
  DELisBS                           false    handle <DEL> as <BACKSPACE>
  printTab                           true    handle <TAB> as printable (prints as space)
  printEuro                          true    handle unicode 0x20AC (Euro sign) as printable
  catchCtrlH                         true    handle ^H as <BACKSPACE>
  closeOnESC                         true    close terminal on <ESC>
  historyUnique                     false    prevent consecutive and identical entries in history
  id                                    0    terminal id
  ps                                  '>'    prompt string
  greeting      '%+r Terminal ready. %-r'    string for greeting if no initHandler is used
  handler                   defaultHandler    reference to handler for command interpretation
  ctrlHandler                        null    reference to handler called on uncatched special keys
  initHandler                        null    reference to handler called at end of init()
  exitHandler                        null    reference to handler called on close()
  wrapping                          false    text wrapping for `write()' on/off
  mapANSI                           false    enable mapping of ANSI escape sequences (SGR only)
  ANSItrueBlack                     false    force ANSI 30m to be rendered as black (default: fg color)


At least you will want to specify `handler' to implement your own command parser.

Note: While `id' is not used by the Termninal object, it provides an easy way to identify
multiple terminals by the use of "this.id". (e.g.: "if (this.id == 1) startupterm = true;")

p.e.:

  // creating two individual Terminal instances

  var term1 = new Terminal(
    {
      id: 1,
      x: 200,
      y: 10,
      cols: 80,
      rows: 12,
      greeting: "*** This is Terminal 1 ***",
      handler: myTerminalHandler
    }
  );
  term1.open();

  var term2 = new Terminal(
    {
      id: 2,
      x, 200,
      y: 220,
      cols: 80
      rows: 12,
      greeting: "*** This is Terminal 2 ***",
      handler: myTerminalHandler
    }
  );
  term2.open();




3   Using the Terminal

There are 4 different handlers that are called by a Terminal instance to process input and
some flags to control the input mode and behaviour.



3.1 The Default Handler (a simlple example for input handling)

If no handlers are defined in the configuration object, a default handler is called to
handle a line of user input. The default command line handler `defaultHandler' just
closes the command line with a new line and echos the input back to the user:

  function termDefaultHandler() {
    this.newLine();
    if (this.lineBuffer != '') {
      this.type('You typed: '+this.lineBuffer);
      this.newLine();
    }
    this.prompt();
  }
  
  // Note: This used to be top level function. With version 1.4 `termDefaultHandler' became
  // a reference to the method `Terminal.prototype.defaultHandler'.

First you may note that the instance is refered to as `this'. So you need not worry about
which Terminal instance is calling your handler. As the handler is entered, the terminal
is locked for user input and the cursor is off. The current input is available as a string
value in `this.lineBuffer'.

The method `type(<text>)' just does what it says and types a string at the current cursor
position to the terminal screen.

`newLine()' moves the cursor to a new line.

The method `prompt()' adds a new line if the cursor isn't at the start of a line, outputs
the prompt string (as specified in the configuration), activates the cursor, and unlocks
the terminal for further input. While you're doing normal command line processing, always
call `prompt()' when leaving your handler.

In fact this is all you need to create your own terminal application. Please see at least
the method `write()' for a more powerful output method.

Below we will refer to all methods of the Terminal object as `Terminal.<method>()'.
You can call them as `this.<method>()' in a handler or as methods of your named instance
in other context (e.g.: "myTerminal.close()").

[In technical terms these methods are methods of the Terminal's prototype object, while
the properties are properties of a Termninal instance. Since this doesn't make any
difference to your script, we'll refer to both as `Terminal.<method-or-property>'.]



3.2 Input Modes

3.2.1 Normal Line Input (Command Line Mode)

By default the terminal is in normal input mode. Any printable characters in the range of
ASCII 0x20 - 0xff are echoed to the terminal and may be edited with the use of the cursor
keys and the <BACKSPACE> key.
The cursor keys UP and DOWN let the user browse in the command line history (the list of
all commands issued previously in this Terminal instance).

If the user presses <CR> or <ENTER>, the line is read from the terminal buffer, converted
to a string, and placed in `Terminal.lineBuffer' (-> `this.lineBuffer') for further use.
The terminal is then locked for further input and the specified handler
(`Terminal.handler') is called.


3.2.1.2 Special Keys (ctrlHandler)

If a special character (ASCII<0x20) or an according combination of <CTRL> and a key is
pressed, which is not caught for editing or "enter", and a handler for `ctrlHandler' is
specified, this handler is called.
The ASCII value of the special character is available in `Terminal.inputChar'. Please note
that the terminal is neither locked, nor is the cursor off - all further actions have to
be controlled by `ctrlHandler'. (The tracking of <CTRL>-<key> combinations as "^C" usually
works but cannot be taken for granted.)

A named reference of the special control values in POSIX form (as well as the values of
the cursor keys [LEFT, RIGHT, UP, DOWN]) is available in the `termKey' object.

Note:
With version 1.4 `termKey' is a reference to `Terminal.prototype.globals.termKey'.
This object is also mapped to `Terminal.prototype.termKey', so you may also access it as
"this.termKey" inside handlers.

p.e.:

  // a simple ctrlHandler

  function myCtrlHandler() {
    if (this.inputChar == termKey.ETX) {
      // exit on ^C (^C == ASCII 0x03 == <ETX>)
      this.close();
    }
  }

If no `ctrlHandler' is specified, control keys are ignored (default).


3.2.2 Raw Mode

If the flag `Terminal.rawMode' is set to a value evaluating to `true', no special keys are
tracked but <CR> and <ENTER> (and <ESC>, if the flag `Terminal.closeOnESC' is set).
The input is NOT echoed to the terminal. All printable key values [0x20-0xff] are
transformed to characters and added to `Terminal.lineBuffer' sequentially. The command
line input is NOT added to the history.

This mode is especially suitable for password input.

p.e.:

  // using raw mode for password input

  function myTermHandler() {
    this.newLine();
    // we stored a flag in Terminal.env to track the status
    if (this.env.getpassword) {
      // leave raw mode
      this.rawMode = false;
      if (passwords[this.env.user] == this.lineBuffer) {
        // matched
        this.type('Welcome '+this.env.user);
        this.env.loggedin = true;
      }
      else {
        this.type('Sorry.');
      }
      this.env.getpassword = false;
    }
    else {
      // simple parsing
      var args = this.lineBuffer.split(' ');
      var cmd = args[0];
      if (cmd == 'login') {
        var user = args[1];
        if (!user) {
          this.type('usage: login <username>');
        }
        else {
          this.env.user = user;
          this.env.getpassword = true;
          this.type('password? ');
          // enter raw mode
          this.rawMode = true;
          // leave without prompt so we must unlock first
          this.lock = false;
          return;
        }
      }
      /*
        other actions ...
      */
    }
    this.prompt();
  }

In this example a handler is set up to process the command "login <username>" and ask for
a password for the given user name in raw mode. Note the use of the object `Terminal.env'
which is just an empty object set up at the creation of the Terminal instance. Its only
purpose is to provide an individual namespace for private data to be stored by a Terminal
instance.

NOTE: The flag `Terminal.lock' is used to control the keyboard locking. If we would not
set this to `false' before leaving in raw mode, we would be caught in dead-lock, since no
input could be entered and our handler wouldn't be called again. - A dreadful end of our
terminal session.

NOTE: Raw mode utilizes the property `Terminal.lastLine' to collect the input string.
This is normally emty, when a handler is called. This is not the case if your script left
the input process on a call of ctrlHandler. You should clear `Terminal.lastLine' in such
a case, if you're going to enter raw mode immediatly after this.


3.2.3 Character Mode

If the flag `Terminal.charMode' is set to a value evaluating to `true', the terminal is in
character mode. In this mode the numeric ASCII value of the next key typed is stored in
`Terminal.inputChar'. The input is NOT echoed to the terminal. NO locking or cursor
control is performed and left to the handler.
You can use this mode to implement your editor or a console game.
`Terminal.charMode' takes precedence over `Terminal.rawMode'.

p.e.: 

  // using char mode

  function myTermHandler() {
    // this is the normal handler
    this.newLine();
    // simple parsing
    var args = this.lineBuffer.split(' ');
    var cmd = args[0];
    if (cmd == 'edit') {
      // init the editor
      myEditor(this);
      // redirect the handler to editor
      this.handler = myEditor;
      // leave in char mode
      this.charMode = true;
      // show cursor
      this.cursorOn();
      // don't forget unlocking
      this.lock = false;
      return;
    }
    /*
      other actions ...
    */
    this.prompt();
  }

  function myEditor(initterm) {
    // our dummy editor (featuring modal behaviour)
    if (initterm) {
      // perform initialization tasks
      initterm.clear();
      initterm.write('this is a simple test editor; leave with <ESC> then "q"%n%n');
      initterm.env.mode = '';
      // store a reference of the calling handler
      initterm.env.handler = initterm.handler;
      return;
    }
    // called as handler -> lock first
    this.lock=true;
    // hide cursor
    this.cursorOff();
    var key = this.inputChar;
    if (this.env.mode == 'ctrl') {
      // control mode
      if (key == 113) {
        // "q" => quit
        // leave charMode and reset the handler to normal
        this.charMode = false;
        this.handler = this.env.handler;
        // clear the screen
        this.clear();
        // prompt and return
        this.prompt();
        return;
      }
      else {
        // leave control mode
        this.env.mode = '';
      }
    }
    else {
      // edit mode
      if (key == termKey.ESC) {
        // enter control mode
        // we'd better indicate this in a status line ...
        this.env.mode = 'ctrl';
      }
      else if (key == termKey.LEFT) {
        // cursor left
      }
      else if (key == termKey.RIGHT) {
        // cursor right
      }
      if (key == termKey.UP) {
        // cursor up
      }
      else if (key == termKey.DOWN) {
        // cursor down
      }
      else if (key == termKey.CR) {
        // cr or enter
      }
      else if (key == termKey.BS) {
        // backspace
      }
      else if (key == termKey.DEL) {
        // fwd delete
        // conf.DELisBS is not evaluated in charMode!
      }
      else if (this.isPrintable(key)) {
        // printable char - just type it
        var ch = String.fromCharCode(key);
        this.type(ch);
      }
    }
    // leave unlocked with cursor
    this.lock = false;
    this.cursorOn();
  }


Note the redirecting of the input handler to replace the command line handler by the
editor. The method `Terminal.clear()' clears the terminal.
`Terminal.cursorOn()' and `Terminal.cursorOff()' are used to show and hide the cursor.



3.3 Other Handlers

There are two more handlers that can be specified in the configuration object:


3.3.1 initHandler

`initHandler' is called at the end of the initialization triggered by `Terminal.open()'.
The default action - if no `initHandler' is specified - is:

  // default initilization

  this.write(this.conf.greeting);
  this.newLine();
  this.prompt();

Use `initHandler' to perform your own start up tasks (e.g. show a start up screen). Keep
in mind that you should unlock the terminal and possibly show a cursor to give the
impression of a usable terminal.


3.3.2  exitHandler

`exitHandler' is called by `Terminal.close()' just before hiding the terminal. You can use
this handler to implement any tasks to be performed on exit. Note that this handler is
called even if the terminal is closed on <ESC> outside of your inputHandlers control.

See the file "multiterm_test.html" for an example.



3.4   Overview: Flags for Behaviour Control

These falgs are accessible as `Terminal.<flag>' at runtime. If not stated else, the
initial value may be specified in the configuration object.
The configuration object and its properties are accessible at runtime via `Terminal.conf'.


  NAME                      DEFAULT VALUE    MEANING

  blink_delay                         500    delay for cursor blinking in milliseconds.

  crsrBlinkMode                     false    true for blinking cursor.
                                             if false, cursor is static.
  
  crsrBlockMode                      true    true for block-cursor else underscore.

  DELisBS                           false    handle <DEL> as <BACKSPACE>.

  printTab                           true    handle <TAB> as printable (prints as space)
                                             if false <TAB> is handled as a control character

  printEuro                          true    handle the euro sign as valid input char.
                                             if false char 0x20AC is printed, but not accepted
                                             in the command line

  catchCtrlH                         true    handle ^H as <BACKSPACE>.
                                             if false, ^H must be tracked by a custom
                                             ctrlHandler.

  closeOnESC                         true    close terminal on <ESC>.
                                             if true, <ESC> is not available for ctrHandler.


  historyUnique                     false    unique history entries.
                                             if true, entries that are identical to the last
                                             entry in the user history will not be added.

  charMode                          false    terminal in character mode (tracks next key-code).
                                             (runtime only)
 
  rawMode                           false    terminal in raw mode (no echo, no editing).
                                             (runtime only)

  wrapping                          false    text wrapping on/off

  mapANSI                           false    filter ANSI escape sequences and apply SGR styles
                                             and color codes for write()

  ANSItrueBlack                     false    force output of ANSI code 30m (black) as black
                                             (default: render color 0 as foreground color)


Not exactly a flag but useful:

  ps                                  '>'    prompt string.




4  Output Methods

Please note that any output to the terminal implies an advance of the cursor. This means,
that if your output reaches the last column of your terminal, the cursor is advanced and
a new line is opened automatically. This procedure may include scrolling to make room for
the new line. While this is not of much interest for most purposes, please note that, if
you output a string of length 80 to a 80-columns-terminal, and a new line, and another
string, this will result in an empty line between the two strings.


4.1  Terminal.type( <text> [,<stylevector>] )

Types the string <text> at the current cursor position to the terminal. Long lines are
broken where the last column of the terminal is reached and continued in the next line.
`Terminal.write()' does not support any kind of arbitrary line breaks. (This is just a
basic output routine. See `Terminal.write()' for a more powerful output method.)

A bitvector may be supplied as an optional second argument to represent a style or a
combination of styles. The meanings of the bits set are interpreted as follows:

<stylevector>:

   1 ... reverse    (2 power 0)
   2 ... underline  (2 power 1)
   4 ... italics    (2 power 2)
   8 ... strike     (2 power 3)
  16 ... bold       (2 power 4)  *displayed as italics, used internally for ANSI-mapping*

So "Terminal.type( 'text', 5 )" types "text" in italics and reverse video.

Note:
There is no bold, for most monospaced fonts (including Courier) tend to render wider in
bold. Since this would bring the terminal's layout out of balance, we just can't use bold
as a style. - Sorry.

The HTML-representation of this styles are defined in "TermGlobals.termStyleOpen" and
"TermGlobals.termStyleClose".
(Version 1.4: "TermGlobals" is now a reference to "Terminal.prototype.globals".)

Version 1.2 introduces additional styles for colors.
Please read also sect. 4.10 "Using Color" for the extended color values.


4.2  Terminal.write( <text> [,<usemore>] )

Writes a text with markup to the terminal. If an optional second argument evaluates to
true, a UN*X-style utility like `more' is used to page the text. The text may be supplied
as a single string (with newline character "\n") or as an array of lines. Any other input
is transformed to a string value before output.

4.2.1 Mark-up:

`Terminal.write()' employs a simple mark-up with the following syntax:

<markup>: %((+|-)<style>|n|CS|%)
   
   where "+" and '-' are used to switch on and off a style, where
   
   <style>:
   
      "i" ... italics
      "r" ... reverse
      "s" ... strike
      "u" ... underline
      
      "p" ... reset to plain ("%+p" == "%-p")
    
   styles may be combined and may overlap. (e.g. "This is %+rREVERSE%-r, %+uUNDER%+iSCORE%-u%-i.")
   
   "%n"  represents a new line (in fact "\n" is translated to "%n" before processing)
   
   "%CS" clears the terminal screen
   
   "%%"  represents the percent character ('%')

Version 1.2 introduces an additional syntax for colors:

	<color-style> ::= %c(<value>|"("<color-label>")")

Please read also sect. 4.10 "Using Color" for the extended color syntax.

Version 1.51 introduces the mapping of ANSI escape sequences. To use this option you must supply
the flag `mapANSI' with a true value in the config-object or set `this.mapANSI' to `true' at run-
time. Currently supported are SGR codes foreground colors and type styles. Other sequences are
just filtered out. See section 4.12 "ANSI Support" for more.


4.2.2 Buffering:

`Terminal.write()' writes via buffered output to the terminal. This means that the
provided text is rendered to a buffer first and then only the visible parts are transfered
to the terminal display buffers. This avoids scrolling delays for long output.

4.2.3 UseMore Mode:

The buffering of `Terminal.write()' allows for pagewise output, which may be specified by
a second boolean argument. If <usemore> evaluates to `true' and the output exceeds the
range of empty rows on the terminal screen, `Terminal.write()' performs like the UN*X
utility `more'. The next page may be accessed by hitting <SPACE> while <q> terminates
paging and returns with the prompt (-> `Terminal.prompt()').

To use this facillity make sure to return immediatly after calling `Terminal.write()' in
order to allow the more-routine to track the user input.
The terminal is set to "charMode == false" afterwards.

p.e.:

  // using Terminal.write as a pager

  function myTermHandler() {
    this.newLine();
    var args = this.lineBuffer.split(' ');
    var cmd = args[0];
    if (cmd == 'more') {
      var page = args[1];
      if (myPages[page]) {
        // Terminal.write as a pager
        this.write(myPages[page], true);
        return;
      }
      else {
        // Terminal.write for simple output
        this.write('no such page.');
      }
    }
    /*
      other actions ...
    */
    this.prompt();
  }


4.2.4 Text Wrap

Starting with version 1.3 "termlib.js" supports automatic text wrapping with
`Terminal.write()'. (Text wrapping is off by default.)

Use `Terminal.wrapOn()' to enable wrapping, use `Terminal.wrapOff()' to turn it off again.
Use the property "wrapping" of the configuration object to turn wrapping globaly on.

For details see sect. 4.11 "Text Wrap - Terminal.wrapOn(), Terminal.wrapOff()"


4.3  Terminal.typeAt( <r>, <c>, <text> [,<stylevector>] )

Output the string <text> at row <r>, col <c>.
For <stylevector> see `Terminal.type()'.
`Terminal.typeAt()' does not move the cursor.


4.4  Terminal.setChar( <charcode>, <r>, <c> [,<stylevector>] )

Output a single character represented by the ASCII value of <charcode> at row <r>, col <c>.
For <stylevector> see `Terminal.type()'.


4.5  Terminal.newLine()

Moves the cursor to the first column of the next line and performs scrolling, if needed.


4.6  Terminal.clear()

Clears the terminal screen. (Returns with cursor off.)


4.7  Terminal.statusLine( <text> [,<stylevector> [,<lineoffset>]] )

All output acts on a logical screen with the origin at row 0 / col 0. While the origin is
fixed, the logical width and height of the terminal are defined by `Terminal.maxCols' and
`Terminal.maxLines'. These are set to the configuration dimensions at initilization and by
`Terminal.reset()', but may be altered at any moment. Please note that there are no bounds
checked, so make sure that `Terminal.maxCols' and `Terminal.maxLines' are less or equal
to the configuration dimensions.

You may want to decrement `Terminal.maxLines' to keep space for a reserved status line.
`Terminal.statusLine( <text>, <style> )' offers a simple way to type a text to the last
line of the screen as defined by the configuration dimensions.

  // using statusLine()

  function myHandler() {
    // ...
    // reserve last line
    this.maxLines = term.conf.rows-1;
    // print to status line in reverse video
    this.statusLine("Status: <none>", 1);
    // ...
  }

For multiple status lines the optional argument <lineoffset> specifies the addressed row,
where 1 is the line closest to the bottom, 2 the second line from the bottom and so on.
(default: 1)


4.8  Terminal.printRowFromString( <r> , <text> [,<stylevector>] )

Outputs the string <text> to row <r> in the style of an optional <stylevector>.
If the string's length exceeds the length of the row  (up to `Terminal.conf.cols'), extra
characteres are ignored, else any extra space is filled with character code 0 (prints as
<SPACE>).
The valid range for <row> is: 0 >= <row> < `Terminal.maxLines'.
`Terminal.printRowFromString()' does not set the cursor.

You could, for example, use this method to output a line of a text editor's buffer.

p.e.:

  // page refresh function of a text editor

  function myEditorRefresh(termref, topline) {
    // termref: reference to Terminal instance
    // topline: index of first line to print
    // lines of text are stored in termref.env.lines
    for (var r=0; r<termref.maxLines; r++) {
      var i = topline + r;
      if (i < termref.env.lines.length) {
        // output stored line
        termref.printRowFromString(r, termref.env.lines[i]);
      }
      else {
        // output <tilde> for empty line
        termref.printRowFromString(r, '~');
      }
    }
    // set cursor to origin
    termref.r = termref.c = 0; // same as termref.cursorSet(0, 0);
  }


4.9  Terminal.redraw( <row> )

Basic function to redraw a terminal row <row> according to screen buffer values.
For hackers only. (e.g.: for a console game, hack screen buffers first and redraw all
changed rows at once.)


4.10  Using Color

With version 1.2 termlib.js introduces support for colors.
Colors are controlled using the styles interface of the type() and write() methods.

Usage:

As any style settings colors are controlled by the "%<style>" markup of the write() method,
where <style> starts with a "c" for "color".

"termlib.js" supports 3 different color systems:

1) The first approach mimics the ANSI color approach as known from most terminals:

There is a set of 16 colors (1 default color and 15 configurable colors):

  color name     code     color string    synonyms
  ----------------------------------------------------------------
  default         0       *empty*         clear, ""
  black           1       #000000
  red             2       #ff0000         red1
  green           3       #00ff00         green1
  yellow          4       #ffff00         yellow1
  blue            5       #0066ff         blue1
  magenta         6       #ff00ff         magenta1
  cyan            7       #00ffff         cyan1
  white           8       #ffffff
  grey            9       #808080         gray
  darkred         A       #990000         red2
  darkgreen       B       #009900         green2
  darkyellow      C       #999900         yellow2
  darkblue        D       #003399         blue2
  darkmagenta     E       #990099         magenta2
  darkcyan        F       #009999         cyan2
 

"default" or "clear" refers always to the configured default color.

Code values from "A" to "F" (may be lower case) indicate hex values from 10 to 15.

You may change the color string using the method
`TermGlobals.setColor( <label>, <colorstring> )', where <label> is the name or code
of a color and <colorstring> a valid CSS color value.


Examples:

  // changing the color string used for "red"
  TermGlobals.setColor( "red", "#880000" );
  TermGlobals.setColor( "2", "#880000" );
  TermGlobals.setColor( 2, "#880000" );
  // changing darkred
  TermGlobals.setColor( "darkred", "#440000" );
  TermGlobals.setColor( "A", "#440000" );
  TermGlobals.setColor( 10, "#440000" );

You may also access the currently used color string using the method
`TermGlobals.getColorString( <label> )' or look up a color's code using
`TermGlobals.getColorCode( <label> )'.

Note on `TermGlobals' and version 1.4 or higher:
`TermGlobals' is now a reference to `Terminal.prototype.globals', so you may also use the
following inside a handler: "this.globals.setColor( 'red', '#880000' );".



Writing with color:

You may switch the color using the markup "%c(<color name>)" and switch back to the default
color using "%c(default)" or "%c(clear)" or just "%c()" or "%c0".

Alternatively to color names you may use a one-digit hex code "%+c<color-code>" where
<color-code> is in the range from "0" to "F" (case insensitive).

Examples:

  myTerm.write("Switching to %c(red)RED%c(default) and back again.");
  myTerm.write("Switching to %c2RED%c0 and back again.");
  
  myTerm.write("Switching to %c(darkred)DARKRED%c() and back again.");
  myTerm.write("Switching to %caDARKRED%c0 and back again.");
  
With version 1.4 or higher you may also use a color code (hex or decimal) inside brackets
(resulting in a unified color markup syntax "%c(...)"):

  myTerm.write("Switching to %c(2)RED%c(0) and back again.");
  myTerm.write("Switching to %c(02)RED%c(0) and back again.");
  
  myTerm.write("Switching to %c(a)DARKRED%c() and back again.");
  myTerm.write("Switching to %c(10)DARKRED%c() and back again.");


Note that %c0, %c(0), %c(), %c(default), %c(clear) are just synonyms for the default color.
For the following examples we'll use "%c()" for this.


All the color names and codes are case insensitive ("RED" == "red").
As with all styles, setting a color applies to the single write() only.

Using the type() method the color values correspond to the bytes 8 to 11 (bitmask xf00) of
the style-vector. (This means you have to multiply the color code by 256 or 0xff.)

Examples:

  myTerm.type("This is green.", 3*256);
  myTerm.type("This is green and reverse.", 3*256 + 1);

 
2) Using named web colors (Netscape colors)

As a second approach you may use any of the 16 standard named colors or any of the 120
additional Netscape colors.

All you have to do to access this second color set is to prefix the color name with "@".

Examples:

  myterm.write("Switching to %c(@burlywood)burlywood%c() and back again.");
  myterm.write("Switching to %c(@lightseagreen)lightseagreen%c() and back again.");


There are no color codes associated with this. Internally the bits 8 to 15 of the style
vector (bitmask 0xff00) are used for these colors. (Values start with or 0x1000.)

The names of these 136 colors are:

aliceblue antiquewhite aqua aquamarine azure beige black blue blueviolet brown burlywood
cadetblue chartreuse chocolate coral cornflowerblue cornsilk crimson darkblue darkcyan
darkgoldenrod darkgray darkgreen darkkhaki darkmagenta darkolivegreen darkorange
darkorchid darkred darksalmon darkseagreen darkslateblue darkslategray darkturquoise
darkviolet deeppink deepskyblue dimgray dodgerblue firebrick floralwhite forestgreen
fuchsia gainsboro ghostwhite gold goldenrod gray green greenyellow honeydew hotpink
indianred indigo ivory khaki lavender lavenderblush lawngreen lemonchiffon lightblue
lightcoral lightcyan lightgoldenrodyellow lightgreen lightgrey lightpink lightsalmon
lightseagreen lightskyblue lightslategray lightsteelblue lightyellow lime limegreen linen
maroon mediumaquamarine mediumblue mediumorchid mediumpurple mediumseagreen
mediumslateblue mediumspringgreen mediumturquoise mediumvioletred midnightblue mintcream
mistyrose moccasin navajowhite navy oldlace olive olivedrab orange orangered orchid
palegoldenrod palegreen paleturquoise palevioletred papayawhip peachpuff peru pink plum
powderblue purple red rosybrown royalblue saddlebrown salmon sandybrown seagreen seashell
sienna silver skyblue slateblue slategray snow springgreen steelblue tan teal thistle
tomato turquoise violet wheat white whitesmoke yellow yellowgreen

As above all color names are not case sensitive.

The values of this color set is fixed, you cannot change them using
TermGlobals.setColor(). (The codes of this set are mapped internally to color strings.
Changing these would be possible, but would not make much sense.)

 
3) Using the web color set

Finally you may use any of the 216 standard web colors.
You access these by a leading "# and the 6-hex-digit color code of the color.
(You may use also the 3-digit CSS format for these colors).

Examples:

  myterm.write("Switching to %c(#ff0000)red%c() and back again.");
  myterm.write("Switching to %c(#f00)red%c() and back again.");

Again there are no accessible color codes associated to these. Internally these colors are
mapped to the bitmask 0xff0000 of the style vector.

If the given color code is not part of the web color set, but represents a valid color in
6-digit format or in short 3-digit notation, the color will be matched to the nearest web
color available (e.g. "#9a44ee" => "#9933ff").

The available color codes are (in long notation):

000000 000033 000066 000099 0000cc 0000ff 003300 003333 003366 003399 0033cc 0033ff 006600
006633 006666 006699 0066cc 0066ff 009900 009933 009966 009999 0099cc 0099ff 00cc00 00cc33
00cc66 00cc99 00cccc 00ccff 00ff00 00ff33 00ff66 00ff99 00ffcc 00ffff 330000 330033 330066
330099 3300cc 3300ff 333300 333333 333366 333399 3333cc 3333ff 336600 336633 336666 336699
3366cc 3366ff 339900 339933 339966 339999 3399cc 3399ff 33cc00 33cc33 33cc66 33cc99 33cccc
33ccff 33ff00 33ff33 33ff66 33ff99 33ffcc 33ffff 660000 660033 660066 660099 6600cc 6600ff
663300 663333 663366 663399 6633cc 6633ff 666600 666633 666666 666699 6666cc 6666ff 669900
669933 669966 669999 6699cc 6699ff 66cc00 66cc33 66cc66 66cc99 66cccc 66ccff 66ff00 66ff33
66ff66 66ff99 66ffcc 66ffff 990000 990033 990066 990099 9900cc 9900ff 993300 993333 993366
993399 9933cc 9933ff 996600 996633 996666 996699 9966cc 9966ff 999900 999933 999966 999999
9999cc 9999ff 99cc00 99cc33 99cc66 99cc99 99cccc 99ccff 99ff00 99ff33 99ff66 99ff99 99ffcc
99ffff cc0000 cc0033 cc0066 cc0099 cc00cc cc00ff cc3300 cc3333 cc3366 cc3399 cc33cc cc33ff
cc6600 cc6633 cc6666 cc6699 cc66cc cc66ff cc9900 cc9933 cc9966 cc9999 cc99cc cc99ff cccc00
cccc33 cccc66 cccc99 cccccc ccccff ccff00 ccff33 ccff66 ccff99 ccffcc ccffff ff0000 ff0033
ff0066 ff0099 ff00cc ff00ff ff3300 ff3333 ff3366 ff3399 ff33cc ff33ff ff6600 ff6633 ff6666
ff6699 ff66cc ff66ff ff9900 ff9933 ff9966 ff9999 ff99cc ff99ff ffcc00 ffcc33 ffcc66 ffcc99
ffcccc ffccff ffff00 ffff33 ffff66 ffff99 ffffcc ffffff

As above all color codes are not case sensitive.

The values of this color set is fixed, you cannot change them using
`TermGlobals.setColor()'. (The codes of this set are mapped internally to color strings.
Changing these would be possible, but would not make much sense.)


All this adds up to the complete color-markup syntax:

  <color-markup>     ::= "%c"<color-expression>
  <color-expression> ::= <hex-digit> | <label-expression>
  <label-expression> ::= "("<internal-color>|"@"<netscape-color>"|#"<web-color>")"
  <hex-digit>        ::= "0" - "F"
  <internal-color>   ::= any of the names referring to the 16 internal colors
                         or any decimal or hex value 0 <= n < 15
  <netscape-color>   ::= any of the names of the 136 named netscape colors
  <web-color>        ::= any of the codes of the 216 standard web colors


In short, there are three color sets available:

    * One for configurable colors, you access them by a hex digit or "(<name>)"
    * One for netscape color names, you access them by "(@<name>)"
    * One for web colors, you access them by "(#<code>)"

Generally any color-markup begins with "%c" and is followed by one of the three notations.
"%c0", "%c()", or "%c(default)" switch back to the default color.

Supplying an invalid or non-matching color label or value will result in switching back to
the default color. (e.g. "%c(xxx)" == "%c()")


For general style issues c.f. sect 4.1 "Terminal.type()" and sect 4.2 "Terminal.write()".



4.11  Text Wrap - Terminal.wrapOn(), Terminal.wrapOff()

Starting with version 1.3 there is built in support for automatic text wrapping.
Text wrapping is OFF by default.

Please note that text wrapping is only supported for the `write()' method.

Set the property "wrapping" of the configuration to `true' object to turn wrapping on
globally.

To turn on/of wrapping at run time use one of the following:

    * use `Terminal.wrapOn()' to turn wrapping on
    * use `Terminal.wrapOff()' to turn wrapping off
    * set the the flag `Terminal.wrapping' to true/false.

"termlib.js" even supports conditional/soft word breaks: Use the <form feed>-character
("\f" == ASCII 12) for a conditional word break.

Wrapping behaviours are configured on a per-character basis in `TermGlobals.wrapChars':

TermGlobals.wrapChars = {
  // values: 1 = white space, 2 = wrap after, 3 = wrap before, 4 = conditional word break
  9:  1, // tab
  10: 1, // new line - don't change this (used internally)!!!
  12: 4, // form feed (use this for conditional word breaks)
  13: 1, // cr
  32: 1, // blank
  40: 3, // (
  45: 2, // dash/hyphen
  61: 2, // =
  91: 3, // [
  94: 3, // caret (non-printing chars)
  123:3  // {
}

values and meanings:
   1 ... white space, ommited at line ends
   2 ... wrap only after (e.g. a dash/hyphen)
   3 ... wrap before
   4 ... conditional/soft word break (in breaks substituted by a hyphen ASCII 45)

The default configuration evaluetes to this:
	* break on (e.g. space, tab), ommit these chars at line ends
	* break after "-" and "="
	* break before "(", "[", "{", and non-printable (caret)
	* soft break at form feeds (\f)


4.12  ANSI Support

Version 1.51 introduces limited support for ANSI escape sequences.
If the option `mapANSI' is set to `true', any ANSI-sequences are filtered from the
input stream of the method `write()' and translated to internal markup.
Currently only a subset of the SGR (Select Graphic Rendition) codes are supported.
Other sequences are just deleted from the input stream.

ANSI escape sequences are of the form <CSI><parameters><letter>

where

   * CSI is either the multi-byte the Sequence <escape> (0x19) "["
         or the single escape character 0x9b (decimal 155)

   * parameters is either a single number, a semicolon-separated list of numbers,
         or empty
   
   * letter a upper- or lower-case letter (currently only "m" supported)


List of supported SGR codes (letter "m"):

code    effect                 notes
-------------------------------------------------------------------------------
0       Reset / Normal         default rendition (implementation-defined),
                               cancels the effect of any preceding occurrence of SGR
1       Intensity: Bold        rendered as italics by default, see note
3       Italics: on
4       Underline: Single
7       Negative Image         reverse
9       Crossed-out            characters still legible but marked as to be deleted
21      Underline: Double      rendered as simple underline
22      Intensity: Normal      not bold
23      Italics: off
24      Underline: off         both single and double
27      Positive Image         reverse off
29      not crossed out
30-39   Set foreground color,
        normal intensity       3x, see color table
90-99   Set foreground color,
        high intensity         9x, see color table

Color Table

code    name         internal     notes
                  representation
------------------------------------------------------------------
30      black           0         default foreground color, or
                        1         with option ANSItrueBlack = true
31      red             10
32      green           11
33      yellow          12
34      blue            13
35      magenta         14
36      cyan            15          
37      white           #999      effect: light grey
39      reset           0
90      bright black    9         effect: dark grey
91      bright red      2
92      bright green    3
93      bright yellow   4
94      bright blue     5
95      bright magenta  6
96      bright cyan     7
97      bright white    8
99      reset           0         (not a standard)


Note on bold (1m): As bold type is not a sane font-face on default, "bold" is rendered
as italics by default. For this a special internal style 16, markup-charcter "b" is used.

You may override this setting for true bold face by assigning a new style:

   TermGlobals.assignStyle(
      16,      // style code
      "b",     // markup character
      "<b>",   // html start string
      "</b>"   // html end string
   );

Make sure to define CSS with proper letter-spacing to compansate for the wider character
widths of bold type. (See the "sample_style_settings.html" for further information.)

As ANSI-mapping will be considered for the use with server-generated text files, it will
be usefull to escape any "%" (termlib.js markup escape) in the text first. You may find
the method `escapeMarkup(<text>)' handy for this purpose.

Usage Example:

   var myterm = new Terminal(
      {
         mapANSI: true,       // enable ANSI mapping
         ANSItrueBlack: true  // force black in stead of renderung as fg color
      }
    );
 
    myterm.open();
    var escapedText = myterm.escapeMarkup( ANSIencodedText );
    myterm.write( escapedText, true );


All ANSI-code-to-markup-mapping is defined in the static object
"Terminal.prototype.globals.ANIS_SGR_codes" (or short: "TermGlobals.ANIS_SGR_codes").

See the file "sample_ansi_mapping.html" for further information.




5  Cursor Methods and Editing


5.1  Terminal.cursorOn()

Show the cursor.


5.2  Terminal.cursorOff()

Hide the cursor.


5.3  Terminal.cursorSet( <r>, <c> )

Set the cursor position to row <r> column <c>.
`Terminal.cursorSet()' preserves the cursor's active state (on/off).


5.4  Terminal.cursorLeft()

Move the cursor left. (Movement is restricted to the logical input line.)
`Terminal.cursorLeft()' preserves the cursor's active state (on/off).


5.5  Terminal.cursorRight()

Move the cursor right. (Movement is restricted to the logical input line.)
`Terminal.cursorRight()' preserves the cursor's active state (on/off).


5.6  Terminal.backspace()

Delete the character left from the cursor, if the cursor is not in first position of the
logical input line.
`Terminal.backspace()' preserves the cursor's active state (on/off).


5.7  Terminal.fwdDelete()

Delete the character under the cursor.
`Terminal.fwdDelete()' preserves the cursor's active state (on/off).


5.8  Terminal.isPrintable( <key code> [,<unicode page 1 only>] )

Returns `true' if the character represented by <key code> is printable with the current
settings. An optional second argument <unicode page 1 only> limits the range of valid
values to 255 with the exception of the Euro sign, if the flag `Terminal.printEuro' is set.
(This second flag is used for input methods but not for output methods. So you may only
enter portable characters, but you may print others to the terminals screen.)




6  Other Methods of the Terminal Object

6.1  Terminal.prompt()

Performes the following actions:

  * advance the cursor to a new line, if the cursor is not at 1st column
  * type the prompt string (as specified in the configuaration object)
  * show the cursor
  * unlock the terminal

(The value of the prompt string can be accessed and changed in `Terminal.ps'.)


6.2  Terminal.reset()

Resets the terminal to sane values and clears the terminal screen.


6.3  Terminal.open()

Opens the terminal. If this is a fresh instance, the HTML code for the terminal is
generated. On re-entry the terminal's visibility is set to `true'. Initialization tasks
are performed and the optional initHandler called. If no initHandler is specified in the
configuration object, the greeting (configuration or default value) is shown and the user
is prompted for input.

v.1.01: `Terminal.open()' now checks for the existence of the DHTML element as defined in
        `Terminal.conf.termDiv' and returns success.


6.4  Terminal.close()

Closes the terminal and hides its visibility. An optional exitHandler (specified in the
configuration object) is called, and finally the flag `Terminal.closed' is set to true. So
you can check for existing terminal instances as you would check for a `window' object
created by `window.open()'.

p.e.:

  // check for a terminals state
  // let array "term" hold references to terminals

  if (term[n]) {
    if (term[n].closed) {
      // terminal exists and is closed
      // re-enter via "term[n].open()"
    }
    else {
      // terminal exists and is currently open
    }
  }
  else {
    // no such terminal
    // create it via "term[n] = new Terminal()"
  }


6.5  Terminal.focus()

Set the keyboard focus to this instance of Terminal. (As `window.focus()'.)


6.6  Terminal.moveTo( <x>, <y> )

Move the terminal to position <x>/<y> in px.
(As `window.moveTo()', but inside the HTML page.)


6.7  Terminal.resizeTo( <x>, <y> )

Resize the terminal to dimensions <x> cols and <y> rows.
<x> must be at least 4, <y> at least 2.
`Terminal.resizeTo()' resets `Terminal.conf.rows', `Terminal.conf.cols',
`Terminal.maxLines', and `Terminal.maxCols' to <y> and <x>, but leaves the instance' state
else unchanged. Clears the terminal's screen and returns success.

(A bit like `window.resizeTo()', but with rows and cols instead of px.)


6.8  Terminal.getDimensions()

Returns an object with properties "width" and "height" with numeric values for the
terminal's outer dimensions in px. Values are zero (0) if the element is not present or
if the method fails otherwise.


6.9  Terminal.rebuild()

Rebuilds the Terminal object's GUI preserving its state and content.
Use this to change the color theme on the fly.

p.e.:

   // change color settings on the fly
   // here: set bgColor to white and font style to "termWhite"
   // method rebuild() updates the GUI without side effects

   term.conf.bgColor = '#ffffff';
   term.conf.fontClass = 'termWhite';
   term.rebuild();


6.10  Terminal.backupScreen()

Backups the current terminal screen, state, and handlers to the internal object
"backupBuffer". Use this if you want to go full screen or if you want to display an
interactive dialog or a warning. Use `Terminal.restoreScreen()' to restore the former
state of the terminal instance. (See the file "sample_globbing.html" for an example.)

Please note that any call of method `Terminal.rebuild()' will clear the buckup buffer
to avoid any errors or undefined cases resulting from changing screen sizes.


6.11  Terminal.restoreScreen()

Restores a terminal instance from a backup made by a previous call to
`Terminal.backupScreen()'. This resets the screen, the terminal's state and handlers.


6.12  Terminal.swapBackup()

Swaps the backup buffer and the current state of the terminal instance. (E.g.: do/undo)
If the backup buffer is empty (null), just like `Terminal.backupScreen()'.





7   Global Static Methods (TermGlobals)


Note:
With version 1.4 TermGlobals is just a reference mapped to "Terminal.prototype.globals".
So inside a handler these properties and methods may also be accessed as "this.globals".


7.1  TermGlobals.setFocus( <termref> )

Sets the keyboard focus to the instance referenced by <termref>.
The focus is controlled by `TermGlobals.activeTerm' which may be accessed directly.
See also: `Terminal.focus()'


7.2  TermGlobals.keylock (Global Locking Flag)

The global flag `TermGlobals.keylock' allows temporary keyboard locking without any
other change of state. Use this to free the keyboard for any other resources.
(added in v.1.03)


7.3  TermGlobals Text Methods

There is a small set of methods for common terminal related string tasks:


7.3.1  TermGlobals.normalize( <n>, <fieldlength> )

Converts a number to a string, which is filled at its left with zeros ("0") to the total
length of <filedlength>. (e.g.: "TermGlobals.normalize(1, 2)" => "01")


7.3.2  TermGlobals.fillLeft( <value>, <fieldlength> )

Converts a value to a string and fills it to the left with blanks to <fieldlength>.


7.3.3  TermGlobals.center( <text>, <length> )

Adds blanks at the left of the string <text> until the text would be centered at a line
of length <length>. (No blanks are added to the the right.)


7.3.4  TermGlobals.stringReplace( <string1>, <string2>, <text> )

Replaces all occurences of the string <string1> in <text> with <string2>.
This is just a tiny work around for browsers with no support of RegExp.


7.4  TermGlobals Import Methods

There are three different methods to import/paste a text string to the active instance
of Terminal:


7.4.1  TermGlobals.insertText( <string> )

Inserts the given string at the current cursor position. Use this method to paste a
single line of text (e.g.: as part of a command) to the terminal.
Returns a boolean value success.
(If there is no active terminal, or the terminal is locked or the global keylock
`TermGlobals.keylock' is set to `true', the method will return false to indicate
its failing. Else the method returns true for success.)

7.4.2  TermGlobals.importEachLine( <string> )

Breaks the given string to lines and imports each line to the active terminal.
Each line will be imported and executed sequentially (just as a user would have typed
it on the keyboard and hit <ENTER> afterwards).
Any text in the current command line will be lost.
Returns success (see 7.4.1).

7.4.3  TermGlobals.importMultiLine( <string> )

Imports the given string to the active terminal. The text will be imported as single
string and executed once. The text will be available in the terminal's `lineBuffer'
property with any line breaks normalized to newlines (\n).
As with `TermGlobals.importEachLine()' any text in the current command line will be
lost.
Returns success (see 7.4.1).


7.5  TermGlobals.assignStyle( <style-code>, <markup>, <HTMLopen>, <HTMLclose> )

`TermGlobals.assignStyle()' allows you to install a custom style (new with vers. 1.4).
You usually would want to install a new style before opening any instance of Terminal
in order to have the style ready for use.

`TermGlobals.assignStyle()' takes for arguments:

    <style-code>: a number to be used in the style vector to identify this style.
                  <style-code> must be power of 2 between 0 and 256
                  (<style-code> = 2^n, 0 <= n <= 7)
	
	<markup>:     a one letter string to be used for markup (case insensitive)
	
	<HTMLopen>:   the (heading) opening HTML clause for a range in this style
	
	<HTMLclose>:  the (trailing) closing HTML clause for a range in this style


Example 1:

    // install style #32 as bold, markup "b"

    TermGlobals.assignStyle( 32, 'b', '<b>', '</b>' );
    
    // now we may use this in a write statement:
    
    myTerm.write( 'This is %+bBOLD%-b.' );


Example 2:

    // override strike (#16) to be displayed as bold:
    TermGlobals.assignStyle( 16, 'b', '<b>', '</b>' );
    

Please mind that "c" and "p" are reserved markup-codes.
"termlib.js" has the following preinstalled styles in use:

    STYLE-CODE  MARK-UP  MEANING
    
    1           "r"      reverse
    2           "u"      underline
    4           "i"      italics
    8           "s"      strike
   16           "b"      bold (renders as italics, used internally for ANSI-mapping)

You would usually not want to change style #1 (reverse) since this style is used
for the cursor in block mode.
(The same applies for #2 / underline for the cursor, when block mode is off.)

Unlike all other methods of termlib.js `TermGlobals.assignStyle()' alerts any errors.
(Since these errors will usually be detected in development phase, these alerts should
not bother the users of your application.)




8   Localization

The strings and key-codes used by the more utility of `Terminal.write()' are the only
properties of "termlib.js" that may need localization. These properties are defined in
`TermGlobals'. You may override them as needed:

PROPERTY                                      STANDARD VALUE                  COMMENT

TermGlobals.lcMorePrompt1                                    ' -- MORE -- '   1st string
TermGlobals.lcMorePromtp1Style                                            1   reverse
TermGlobals.lcMorePrompt2       ' (Type: space to continue, \'q\' to quit)'   appended string
TermGlobals.lcMorePrompt2Style                                            0   plain
TermGlobals.lcMoreKeyAbort                                              113   (key-code: q)
TermGlobals.lcMoreKeyContinue                                            32   (key-code <SPACE>)


As "TermGlobals.lcMorePrompt2" is appended to "TermGlobals.lcMorePrompt1" make sure that
the length of the combined strings does not exceed `Terminal.conf.cols'.

Note:
With version 1.4 TermGlobals is just a reference mapped to "Terminal.prototype.globals".
So inside a handler these properties may also be accessed as "this.globals".




9   The Socket Extension (Remote Communication)

The socket extension provides an easy way to integrate any AJAX/JSON
requests for server-client communication into "termlib.js".

The socket extension provides an easy way for client-server
communication via asynchronous XMLHttpRequests (commonly known as AJAX or JSON).

See the file "sample_socket.html" for an example.


9.1  A First Example

The socket extension provides a tight integration for all XMLHttpRequest
tasks that would commonly occur in a real world application.

All you have to do, is call the new send( <options> ) method and return.
The request (might it succeed or fail) will come back to your
callback-handler with your Terminal instance set as the this object.

example:

  // assume we are inside a handler
  // ("this" refers to an instance of Terminal)
  
  var myDataObject = {
      book: 'Critique of pure reason',
      chapter: 7,
      page: 4
  };
  
  this.send(
    {
      url:      "my_service.cgi",
      method:   "post",
      data:     myDataObject,
      callback: mySocketCallback
    }
  );
  return;
  
  function mySocketCallback() {
    if (this.socket.succes) {
       // status 200 OK
       this.write("Server said:\n" + this.socket.responseText);
    }
    else if (this.socket.errno) {
       // connection failed
       this.write("Connection error: " + this.socket.errstring);
    }
    else {
       // connection succeeded, but server returned other status than 2xx
       this.write("Server returned: " +
                  this.socket.status + " " + this.socket.statusText);
    }
    this.prompt()
  }

 
9.2  The send() API

As send( <options> ) is called the socket library creates a
XMLHttpRequest, collects and escapes the provided data, executes any
initial tasks, and sends the request.

All settings are transfered via a single options-object containing one
ore more of the following options:

  url         the request url, must be on the same host (default "")
  
  method      request method (GET or POST; default GET)
  
  data        request data (default ""), may be of any type, preferably an
              object with key-value pairs.
              the data is serialized and escaped for you by the library. (Please note
              that there might be unexpected results with nested objects or arrays. By
              the way: arrays are serialized as comma separated lists.) For complex
              data structures use a XML-object (true AJAX, see below).
              The resulting string will be either appended to the request url (GET) or
              used as post-body.
            
  callback    the callback-function to handled the response
 
 
  advanced settings:
  
  postbody    Use this for true AJAX (e.g. sending a XML-object to the server)
              If a postbody option is supplied, this will change the behavior as follows:
              1) the request method is forced to "POST"
              2) the postbody will be used instead of any supplied data object
              3) the postbody will be transmitted as is (no serializing or escaping)
              
              (Note: The creation and parsing of XML-objects is out of the scope of this
              document and termlib.js and is therefor left entirely up to you.)
              
  userid      optional user-id for implicit login (transfered without  encryption!)
              
  password    optional password for implicit login (transfered without encryption!)
              
  mimetype    optional MIME-type to override the response's default MIME
  
  headers     optional object (key-value pairs) of HTTP-headers to be included in the
              request
              
  getHeaders  optional array (or object with labels as keys) of HTTP-headers to be
              extracted from the response
  
  timeout     optional individual timeout for this request (default 10000)


send() will add a parameter "_termlib_reqid" with a unique id to every
GET request that doesn't target the local file system (sent from pages
with the "file:" schemes). This additional parameter ensures that MSIE
(MS Internet Explorer) will truly fetch the requested document instead
of serving it from its cache.


A word on local requests:

Please note that local requests (from and to the local file system)
won't work with MSIE 7. (Sorry, ask Bill.) This MSIE 7 error will be
captured as connection error with errno 2 ("Could not open
XMLHttpRequest.").
If a browser requests a local document that does not exist, a 404 (Not
Found) status code will be generated by the library and the errno
property will be set to 5 ("The requested local document was not found.").

 
9.3  Global Config Settings

There are a few global settings in
Terminal.prototype._HttpSocket.prototype (the prototype of the internal
socket object used by the library), which define some default values:

  useXMLEncoding   Boolean flag (default: false) for parameter delimiters
                   if false, parameters will be delimited by "&".
                   if true, parameters will be delimited using ";" (new XML
                   compatible syntax).
  defaulTimeout    Number of ticks (milliseconds, default: 10000 = 10 sec)
                   for request timeout, if not specified else.
  defaultMethod    String (default: "GET"); request method to use, if not
                   specified else.
  forceNewline     Boolean flag (default: true): translate line breaks in
                   the responseText to newlines (\n).

 
9.4  The Callback (Response Handling)

Any request issued by send() will trigger the handler specified by the
callback option (or a basic default-handler). The callback will be
called in any case, should the request succeed, timeout or fail otherwise.

All response data (and some of the request data) is provided in a
temporary "socket object for your convenience. (This temporary object
will be discarded just after the callback returns.) As the this object
points to your instance of Terminal, this object will be available as
"this.socket" inside your callback-handler.

Properties of the socket object:

  status        the HTTP status code (e.g.: 200, 404) or 0 (zero) on timeout
                and network errors
  statusText    the HTTP status text (e.g.: "OK", "Not Found")
  responseText  the transmitted text (response body)
                line breaks will be normalized to newlines (\n) if
                _HttpSocket.prototype.forceNewline == true (default behavior)
  responseXML   the response body as XML object (if applicable)
  success       a simple boolean flag for a 2xx OK response
  headers       object containing any HTTP headers (as key-value pairs) of the
                response, which where requested by the "getHeaders"-option of
                the send().
                the header-labels are unified to "camelCase"
                e.g.: "Content-Length" will be in headers.contentLength
   
  stored request data:
  
  url           the request url as specified in the send() options.
  data          the data you called send() with
  query         the composed query-string or postbody as transmitted to the host
  method        the request method
  errno         the internal error number (0: no error)
  errstring     the internal error message ("": no error)


Some of the response specific data (as status codes, or headers) might
not be present with local connections.


9.5  Error Codes

Connection errors are classified with the following errno and errstring
values:

  errno   errstring                                       label
  
  0       ""                                              OK
  1       "XMLHttpRequest not implemented."               NOTIMPLEMENTED
  2       "Could not open XMLHttpRequest."                FATALERROR
  3       "The connection timed out."                     TIMEOUT
  4       "Network error."                                NETWORKERROR
  5       "The requested local document was not found."   LOCALFILEERROR
 

The labels are implemented as key-value pairs in
Termlib.prototype._HttpSocket.prototype.errno (type "object").
Error codes (errno) are also accessible as this.socket.ErrorCodes at run-time.

example:

  // assume we are inside a handler
  if (this.socket.errno == this.socket.ErrorCodes.TIMEOUT) {
     this.write("Oops, the request encountered a timeout.");
  }


Inside an interactive terminal session you'll usually want to return
just after send() and call prompt() at the end of your callback-handler.
This way the terminal will keep blocked until the callback is finished.

Aside from this, the socket extension provides also the means for
background tasks (e.g. storing temporary status on a server etc.) that
do not need visual feedback or user interaction. Since the requests are
performed and handled asynchronous and object oriented, both will go
side by side.




10   Cross Browser Functions

For DHTML rendering some methods - as needed by the Terminal library - are provided.
These may also be accessed for other purposes.

Note:
With version 1.4 TermGlobals is just a reference mapped to "Terminal.prototype.globals".
So inside a handler these methods may also be accessed as "this.globals".
e.g.: "this.globals.setVisible( 'myDiv', true );"


10.1  TermGlobals.writeElement( <element id>, <text> )

Writes <text> to the DHTML element with id/name <element id>.

10.2  TermGlobals.setElementXY( <element id>, <x>, <y> )

Sets the DHTML element with id/name <element id> to position <x>/<y>.


10.3  TermGlobals.setVisible( <element id>, <value> )

If <value> evaluates to `true' show DHTML element with id/name <element id> else hide it.


10.4  Custom Fixes for Missing String Methods

Although `String.fromCharCode' and `String.prototype.charCodeAt' are defined by ECMA-262-2
specifications, a few number of browsers lack them in their JavaScript implementation. At
compile time custom methods are installed to fix this. Please note that they work only
with ASCII characters and values in the range of [0x20-0xff].


10.5  TermGlobals.setDisplay( <element id>, <value> )

Sets the style.display property of the element with id/name <element id> to the given
<value>. (added with v. 1.06)


10.6  Browser Flags

There are two flags used to control some special cases for the key handlers:

    Terminal.isSafari (Boolean)
    Terminal.isOpera (Boolean)

They are set to `true', if the corresponding web browser is currently in use and default
to `false' else.




11   Architecture, Internals

11.1  Global Entities

The library is designed to leave only a small foot print in the namespace while providing
suitable usability:

  Globals defined in this library:

    Terminal           (Terminal object, `new' constructor and prototype methods)
    TerminalDefaults   (default configuration, static object)
    termDefaultHandler (default command line handler, static function)
    TermGlobals        (common vars and code for all instances, static object and methods)
    termKey            (named mappings for special keys, static object)
    termDomKeyRef      (special key mapping for DOM key constants, static object)
  
  
  With version 1.4 "Terminal" is an entirely self contained object.
  For comfort and backward compatibility these globals Objects remain mapped to the
  following internal properties/objects:
  
    * TerminalDefaults   => Terminal.prototype.Defaults
    * termDefaultHandler => Terminal.prototype.defaultHandler
    * termKey            => Terminal.prototype.globals.termKey
                            see also: Terminal.prototype.termKey
    * TermGlobals        => Terminal.prototype.globals
    * termDomKeyRef      => Terminal.prototype.globals.termDomKeyRef


  Required CSS classes for font definitions: ".term", ".termReverse".



11.2  I/O Architecture

The Terminal object renders keyboard input from keyCodes to a line buffer and/or to a
special keyCode buffer. In normal input mode printable input is echoed to the screen
buffers. Special characters like <LEFT>, <RIGHT>, <BACKSPACE> are processed for command
line editing by the internal key-handler `TermGlobals.keyHandler' and act directly on the
screen buffers. On <CR> or <ENTER> the start and end positions of the current line are
evaluated (terminated by ASCII 0x01 at the beginning which separates the prompt from the
user input, and any value less than ASCII 0x20 (<SPACE>) at the right end). Then the
character representation for the buffer values in this range are evaluated and
concatenated to a string stored in `Terminal.lineBuffer'. As this involves some
ASCII-to-String-transformations, the range of valid printable input characters is limited
to the first page of unicode characters (0x0020-0x00ff).

There are two screen buffers for output, one for character codes (ASCII values) and one
for style codes. Style codes represent combination of styles as a bitvector (see
`Terminal.type' for bit values.) The method `Terminal.redraw(<row>)' finally renders the
buffers values to a string of HTML code, which is written to the HTML entity holding the
according terminal row. The character buffer is a 2 dimensional array
`Terminal.charBuf[<row>][<col>]' with ranges for <row> from 0 to less than
`Terminal.conf.rows' and for <col> from 0 to less than `Terminal.conf.cols'. The style
buffer is a 2 dimensional array `Terminal.styleBuf[<row>][<col>]' with according ranges.

So every single character is represented by a ASCII code in `Terminal.charBuf' and a
style-vector in `Terminal.styleBuf'. The range of printable character codes is unlimitted
but should be kept to the first page of unicode characters (0x0020-0x00ff) for
compatibility purpose. (c.f. 8.4)

Keyboard input is first handled on the `KEYDOWN' event by the handler `TermGlobals.keyFix'
to remap the keyCodes of cursor keys to consistent values. (To make them distinctable from
any other possibly printable values, the values of POSIX <IS4> to <IS1> where chosen.)
The mapping of the cursor keys is stored in the properties LEFT, RIGHT, UP, and DOWN of
the global static object `termKey'. (v.1.4: `Terminal.prototype.globals.termKey')

The main keyboard handler `TermGlobals.keyHandler' (invoked on `KEYPRESS' or by
`TermGlobals.keyFix') does some final mapping first. Then the input is evaluated as
controlled by the flags `Terminal.rawMode' and `Terminal.charMode' with precedence of the
latter. In dependancy of the mode defined and the handlers currently defined, the input
either is ignored, or is internally processed for command line editing, or one of the
handlers is called.
(v.1.4: `TermGlobals.keyHandler' => `Terminal.prototype.globals.keyHandler'
        `TermGlobals.keyFix'     => Terminal.prototype.globals.keyFix')

In the case of the simultanous presecence of two instances of Terminal, the keyboard focus
is controlled via a reference stored in `TermGlobals.activeTerm'. This reference is also
used to evaluate the `this'-context of the key handlers which are methods of the static
Object `TermGlobals'.
(v.1.4: `TermGlobals.activeTerm' => `Terminal.prototype.globals.activeTerm')

A terminal's screen consists of a HTML-table element residing in the HTML/CSS division
spcified in `Terminal.conf.termDiv'. Any output is handled on a per row bases. The
individual rows are either nested sub-divisions of the main divisions (used for browsers
not compatible to the "Gecko" engine) or the indiviual table data elements (<TD>) of the
terminal's inner table (used for browsers employing the "Gecko" engine).
(This implementation was chosen for rendering speed and in order to minimize any screen
flicker.) Any output or change of state in a raw results in the inner HTML contents of a
row's HTML element to be rewritten. Please note that as a result of this a blinking cursor
may cause a flicker in the line containing the cursor's position while displayed by a
browser, which employs the "Gecko" engine.



11.3  Compatibility

Standard web browsers with a JavaScript implementation compliant to ECMA-262 2nd edition
[ECMA262-2] and support for the anonymous array and object constructs and the anonymous
function construct in the form of "myfunc = function(x) {}" (c.f. ECMA-262 3rd edion
[ECMA262-3] for details). This comprises almost all current browsers but Konquerer (khtml)
and versions of Apple Safari for Mac OS 10.0-10.28 (Safari < 1.1) which lack support for
keyboard events.

To provide a maximum of compatibilty the extend of language keywords used was kept to a
minimum and does not exceed the lexical conventions of ECMA-262-2. Especially there is no
use of the `switch' statement or the `RegExp' method of the global object. Also the use of
advanced Array methods like `push', `shift', `splice' was avoided.

The socket extension uses ECMA263-3 (JavaScript 1.5) syntax and requires
an implementation of the XMLHttpRequest object (which is generated via
ActiveX for MSIE).

With version 1.5 (2010/01) support for Netscape 4 (layers) was dropped and the socket
extension was included in the main library. For this the standard requirements are now
to ECMA263-3 (JavaScript 1.5).

Opera related:
The Opera web browser fires some identical events and keyCodes for some extra keys, which
can't be distinguished from the ordinary ones. These are all related to the extended key
pad as listed in the following table:

   keyCode   Normal Key      Opera Irregular
   -----------------------------------------
     35      # (pound mark)  End / Pos 2
     36      $ (dollar)      Home / Pos 1
     46      . (period)      Forward Delete




12   History

This library evolved from the terminal script "TermApp" ((c) N. Landsteiner 2003) and is
in its current form a down scaled spinn-off of the "JS/UIX" project [JS/UIX] (evolution
"JS/UIX v0.5"). c.f.: <http://www.masswerk.at/jsuix>

v 1.01: added Terminal.prototype.resizeTo(x,y)
        added Terminal.conf.fontClass (=> configureable class name)
        Terminal.prototype.open() now checks for element conf.termDiv in advance
          and returns success.

v 1.02: added support for <TAB> and Euro sign
          Terminal.conf.printTab
          Terminal.conf.printEuro
        and method Terminal.prototype.isPrintable(keycode)
        added support for getopt to sample parser ("parser_sample.html")


v 1.03: added global keyboard locking (TermGlobals.keylock)
        modified Terminal.prototype.redraw for speed (use of locals)


v 1.04: modified the key handler to fix a bug with MSIE5/Mac
        fixed a bug in TermGlobals.setVisible with older MSIE-alike browsers without
        DOM support.
        moved the script of the sample parser to an individual document
        => "termlib_parser.js" (HTML document is "parser_sample.html" as before)

v 1.05: added config flag historyUnique.

v 1.06: fixed CTRl+ALT (Windows alt gr) isn't CTRL any more
        -> better support for international keyboards with MSIE/Win.
        fixed double backspace bug for Safari;
        added TermGlobals.setDisplay for setting style.display props
        termlib.js now outputs lower case html (xhtml compatibility)
        (date: 12'2006)

v 1.07: added method Terminal.rebuild() to rebuild the GUI with new color settings.
        (date: 01'2007)

v 1.07a: added sample for text import (see faq).
        (date: 03'2007)

v 1.1:  fixed a bug in 'more' output mode (cursor could be hidden after quit)
        added the socket extension in a separate file "termlib_socket.js".
        (this is a separate file because we break our compatibility guide lines with
        this IO/AJAX library.)
        see chapter 11 for more.
        included some more sample pages.

v 1.2   added color support ("%[+-]c(<color>)" markup)
        moved paste support from sample file to lib
        * TermGlobals.insertText( <text>)
        * TermGlobals.importEachLine( <text> )
        * TermGlobals.importMultiLine( <text> )

v 1.3   added word wrapping to write()
        * activate with myTerm.wrapOn()
        * deactivate with myTerm.wrapOff()
        use conf.wrapping (boolean) for a global setting

v 1.4   Terminal is now an entirely self-contained object
        Global references to inner objects for backward compatipility:
        * TerminalDefaults   => Terminal.prototype.Defaults
        * termDefaultHandler => Terminal.prototype.defaultHandler
        * termKey            => Terminal.prototype.globals.termKey
                        see also: Terminal.prototype.termKey
        * TermGlobals        => Terminal.prototype.globals
        * termDomKeyRef      => Terminal.prototype.globals.termDomKeyRef

        So in effect to outside scripts everything remains the same;
        no need to rewrite any existing scripts.
        You may now use "this.globals" inside any handlers
        to refer to the static global object (TermGlobals).
        You may also refer to key definitions as "this.termKey.*".
        (Please mind that "this.termKey" is a reference to the static object
        and not specific to the instance. A change to "this.termKey" will be
        by any other instances of Terminal too.)
        
        Added a new method TermGlobals.assignStyle() for custom styles & mark up.
        
        Unified the color mark up: You may now use color codes (decimal or hex)
        inside brackets. e.g.: %c(10)DARKRED%c() or %c(a)DARKRED%c()
                
        Added key repeat for remapped keys (cursor movements etc).

v 1.41  Fixed a bug in the word wrapping regarding write() output, when
        the cursor was set with cursorSet() before.
        
        Included the Termlib-Invaders sample application.

v 1.42  Fixed a bug which caused Opera to delete 2 chars at once.
        Introduced new property Terminal.isOpera (Boolean).
        Added a compatibility note on Opera to the "Read Me" (this file, sect. 11.3).

v 1.43  enhanced the ctrlHandler so it also catches ESC if flag closeOnESC
        is set to false. fixed a bug with Safari which fired repeated events
        for the ctrlHandler for TAB if flag printTab was set to false.

v 1.5   Dropped support of Netscape 4 (layers).
        Moved the socket extension ("termlib_socket.js") to the main file.
        Added methods for screen/state backup and restore ("this.backupScreen()" and
        "this.restoreScreen()").
        Changed the license (c.f. sect 14)

v 1.51  Added limited ANSI-support.
        Cleaned up the code a little bit.
        Added a jsmin-compacted version "termlib_compacted.js"

v 1.52  Added method swapBackup().
        Reorganized some of the accompanying files.
        The Parser ("termlib_parse.js") is now a self contained object with a
        constructor (see "parser_sample.html")

v 1.53  Minor tweaks to the accompanying files.
        Compacted versions are now organized in a dedicated subdirectory.

v 1.54  Fixed BACK_SPACE for Opera, DELETE for Safari/WebKit

v 1.55  Fixed dead keys issue for Mac OS (Leapard & later), vowels only.
        (As this needs extensive translation tables, this fixes only
        combinations of "^", "´", "`" with any vowel, and "~" with "n".
        Please give feedback, if you need more.)

v 1.56  Fixed a new ESC-key issue for Safari.

v 1.57  Fixed the dead keys fix: Now only activated for Safari, German (de-de).

v 1.58  Fixed a MS IE issue introduced in the last update.

v 1.59  Dropped dead keys fix, fixed backspace for Safari.



13  Example for a Command Line Parser

  // parser example, splits command line to args with quoting and escape
  // for use as `Terminal.handler'
  
  function commandHandler() {
    this.newLine();
    var argv = [''];     // arguments vector
    var argQL = [''];    // quoting level
    var argc = 0;        // arguments cursor
    var escape = false ; // escape flag
    for (var i=0; i<this.lineBuffer.length; i++) {
      var ch= this.lineBuffer.charAt(i);
      if (escape) {
        argv[argc] += ch;
        escape = false;
      }
      else if ((ch == '"') || (ch == "'") || (ch == "`")) {
        if (argQL[argc]) {
          if (argQL[argc] == ch) {
            argc ++;
            argv[argc] = argQL[argc] = '';
          }
          else {
            argv[argc] += ch;
          }
        }
        else {
          if (argv[argc] != '') {
            argc ++;
            argv[argc] = '';
            argQL[argc] = ch;
          }
          else {
            argQL[argc] = ch;
          }
        }
      }
      else if ((ch == ' ') || (ch == '\t')) {
        if (argQL[argc]) {
          argv[argc] += ch;
        }
        else if (argv[argc] != '') {
          argc++;
          argv[argc] = argQL[argc] = '';
        }
      }
      else if (ch == '\\') {
        escape = true;
      }
      else {
        argv[argc] += ch;
      }
    }
    if ((argv[argc] == '') && (!argQL[argc])) {
      argv.length--;
      argQL.length--;
    }
    if (argv.length == 0) {
      // no commmand line input
    }
    else if (argQL[0]) {
      // first argument quoted -> error
      this.write("Error: first argument quoted by "+argQL[0]);
    }
    else {
      argc = 0;
      var cmd = argv[argc++];
      /*
        parse commands
        1st argument is argv[argc]
        arguments' quoting levels in argQL[argc] are of (<empty> | ' | " | `)
      */
      if (cmd == 'help') {
        this.write(helpPage);
      }
      else if (cmd == 'clear') {
        this.clear();
      }
      else if (cmd == 'exit') {
        this.close();
        return;
      }
      else {
        // for test purpose just output argv as list
        // assemple a string of style-escaped lines and output it in more-mode
        s='   ARG  QL  VALUE%n';
        for (var i=0; i<argv.length; i++) {
          s += this.globals.stringReplace('%', '%%',
                 this.globals.fillLeft(i, 6) +
                 this.globals.fillLeft((argQL[i])? argQL[i]:'-', 4) +
                 '  "' + argv[i] + '"'
            ) + '%n';
        }
        this.write(s, 1);
        return;
      }
    }
    this.prompt();
  }


The file "parser_sample.html" features a stand-alone parser ("termlib_parser.js") very
much like this. You are free to use it according to the termlib-license (see sect. 14).
It provides configurable values for quotes and esape characters and imports the parsed
argument list into a Terminal instance's namespace. ("parser_sample.html" and
"termlib_parser.js" should accompany this file.)




14   License

This JavaScript-library is free.
Include a visible backlink to <http://www.masswerk.at/termlib/> in the embedding web
page or application. The library should always be accompanied by the "readme.txt" and
the sample HTML-documents.

Any changes to the library should be commented and be documented in the readme-file.
Any changes must be reflected in the `Terminal.version' string as
"Version.Subversion (compatibility)".

If you want to support the development of termlib.js, see the section "Donations" below.




15   Disclaimer

This software is distributed AS IS and in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
PURPOSE. The entire risk as to the quality and performance of the product is borne by the
user. No use of the product is authorized hereunder except under this disclaimer.




16   Donations

In case you like termlib.js, are using it commercially, and/or are making profit by its
use, you may want to make a donation to support further maintenance and development or
just to honor the labor and time it incorporates.

You can donate anytime via PayPal:
http://www.masswerk.at/termlib/donate/




17   References

[ECMA262-2] "ECMAScript Language Specification" Standard ECMA-262 2nd Edition
            August 1998 (ISO/IEC 16262 - April 1998)

[ECMA262-3] "ECMAScript Language Specification" Standard ECMA-262 3rd Edition Final
            24 March 2000

[JS/UIX]     JS/UIX - JavaScript Uniplexed Interface eXtension
             <http://www.masswerk.at/jsuix/>





Norbert Landsteiner / Vienna, Aug 2005 - Jan 2010
mass:werk - media environments
<http://www.masswerk.at>
See web site for contact information.
