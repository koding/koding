/*
  termlib_parser.js  v.1.1
  command line parser for termlib.js
  (c) Norbert Landsteiner 2005-2010
  mass:werk - media environments
  <http://www.masswerk.at>

  you are free to use this parser under the "termlib.js" license.
  
  Synopsis:
  
  var parser = new Parser();
  parser.parseLine(this);
  var command = this.argv[this.argc++];

  Usage:

     Call method "parseLine(this)" from inside of your Terminal-handler.
     This will parse the current command line to chunks separated by any amount of
     white space (see property whiteSpace).
     "parseLine" will inject the following properties into the Terminal instance:

       this.argv:  Array of parsed chunks (words, arguments)
       this.argQL: Array of quoting level per argument
                   This array will contain the according quote character or an
                   empty string for each element of argv with the same index
       this.argc:  A pointer to this.argv and this.argQL
                   (initially set to 0; used by method getopt)

     E.g.: For the string: This is "quoted".
           argv will result to ['this', 'is', 'quoted', '.']
           and argQL will result to ['', '', '"', '']
           if '"' is defined as a quote character (default: ', ", and `)

     getopt(this, "<options>")
     Call this method from inside of your handler to parse any options from the
     next chunk in this.argv that this.argc points to.
     Options are considered any arguments preceded by an option character in the
     property optionChars (default: "-"). The second argument is a string
     containing all characters to be considered legal option flags.
     The method returns an object with a property of type object for any option
     flag (defined as a character in the options-string) found in argv.
     argc will be advanced to the first element of argv that is not an option.
     Each of the flag-objects will contain the property `value'.
     In case that the option flag was immediately followed by  a number
     (unsigned float value), this will be stored as a number in the value,
     otherwise the value will be set to -1.
     Any flags that were not defined in the options-string will be stored as
     an array of chars in the property `illegals' of the returned object.

     E.g.:

        this.argv: ["test", "-en7a", "-f", "next"]
        this.argc: set initially to 0

        var command = this.argv[this.argc++];    // this.argc now points to 2nd chunk
        var options = parser.getopt(this, "en");

        getopt will return the following object:
        {
          'e': { value: -1 },
          'n': { value: 7 },
          'illegals': ['a', 'f']
        }
        and this.argc will be set to 3, pointing to "next".

     Escape expressions:
     The parser can handle escape sequences, e.g.: hexdecimal notations of
     characters that are preceded by an escape character. (default: parse any
     2-byte hex expressions preceded by "%" as a character,  e.g. "%41" => "A")
     Escape characters are defined in the property escapeExpressions with the
     according method as their value. (The given function or method must be present
     at creation and takes four arguments: terminal instance, current char-position,
     the escape character found, and the current quoting level. The method or function
     is expected to strip any escape sequence of the lineBuffer and to return a string
     to be inserted at the current parsing position.)
     The result of an escape expression will allways add to the current chunk and will
     never result in parsed white space.

  Configuration: you may want to overide the follow objects (or add properties):
     parser.whiteSpace:        chars to be parsed as white space
     parser.quoteChars:        chars to be parsed as quotes
     parser.singleEscapes:     chars to escape a quote or escape expression
     parser.optionChars:       chars that start an option
     parser.escapeExpressions: chars that start escape expressions

  v. 1.1: Parser is now a function with a constructor.
  Configurations can be handled at a per-instance basis.
  Parser is now a single, self-contained object in the global name space.
  Note: we are not storing the terminal instance in order to avoid memory leakage.
*/

function Parser() {
	// config:
	
	// chars to be parsed as white space
	this.whiteSpace = {
		' ': true,
		'\t': true
	};
	
	// chars to be parsed as quotes
	this.quoteChars = {
		'"': true,
		"'": true,
		'`': true
	};
	
	// chars to be parsed as escape char
	this.singleEscapes = {
		'\\': true
	};
	
	// chars that mark the start of an option-expression
	// for use with getopt
	this.optionChars = {
		'-': true
	};
	
	// chars that start escape expressions (value = handler)
	// plugin handlers for ascii escapes or variable substitution
	this.escapeExpressions = {
		'%': Parser.prototype.plugins.hexExpression
	};
}
	
Parser.prototype = {
	version: '1.1',
	
	plugins: {
		hexExpression: function(termref, charindex, escapechar, quotelevel) {
			/* example for a plugin for Parser.escapeExpressions
			   params:
				 termref:    reference to Terminal instance
				 charindex:  position in termref.lineBuffer (escapechar)
				 escapechar: escape character found
				 quotelevel: current quoting level (quote char or empty)
			   (quotelevel is not used here, but this is a general approach to plugins)
			   the character in position charindex will be ignored
			   the return value is added to the current argument
			*/
			// convert hex values to chars (e.g. %20 => <SPACE>)
			if (termref.lineBuffer.length > charindex+2) {
				// get next 2 chars
				var hi = termref.lineBuffer.charAt(charindex+1);
				var lo = termref.lineBuffer.charAt(charindex+2);
				lo = lo.toUpperCase();
				hi = hi.toUpperCase();
				// check for valid hex digits
				if ((((hi>='0') && (hi<='9')) || ((hi>='A') && ((hi<='F')))) &&
					(((lo>='0') && (lo<='9')) || ((lo>='A') && ((lo<='F'))))) {
					// next 2 chars are valid hex, so strip them from lineBuffer
					Parser.prototype.plugins._escExprStrip(termref, charindex+1, charindex+3);
					// and return the char
					return String.fromCharCode(parseInt(hi+lo, 16));
				}
			}
			// if not handled return the escape character (=> no conversion)
			return escapechar;
		},
	
		_escExprStrip: function(termref, from, to) {
			// strip characters from termref.lineBuffer (for use with escape expressions)
			termref.lineBuffer =
				termref.lineBuffer.substring(0, from) +
				termref.lineBuffer.substring(to);
		}
	},
	
	getopt: function(termref, optsstring) {
		// scans argv form current position of argc for opts
		// arguments in argv must not be quoted
		// returns an object with a property for every option flag found
		// option values (absolute floats) are stored in Object.<opt>.value (default -1)
		// the property "illegals" contains an array of  all flags found but not in optstring
		// argc is set to first argument that is not an option
		var opts = { 'illegals':[] };
		while ((termref.argc < termref.argv.length) && (termref.argQL[termref.argc]==''))  {
			var a = termref.argv[termref.argc];
			if ((a.length>0) && (this.optionChars[a.charAt(0)])) {
				var i = 1;
				while (i<a.length) {
					var c=a.charAt(i);
					var v = '';
					while (i<a.length-1) {
						var nc=a.charAt(i+1);
						if ((nc=='.') || ((nc>='0') && (nc<='9'))) {
							v += nc;
							i++;
						}
						else {
							break;
						}
					}
					if (optsstring.indexOf(c)>=0) {
						opts[c] = (v == '')? {value:-1} : (isNaN(v))? {value:0} : {value:parseFloat(v)};
					}
					else {
						opts.illegals[opts.illegals.length]=c;
					}
					i++;
				}
				termref.argc++;
			}
			else {
				break;
			}
		}
		return opts;
	},
	
	parseLine: function(termref) {
		// stand-alone parser, takes a Terminal instance as argument
		// parses the command line and stores results as instance properties
		//   argv:  list of parsed arguments
		//   argQL: argument's quoting level (<empty> or quote character)
		//   argc:  cursur for argv, set initinally to zero (0)
		// open quote strings are not an error but automatically closed.
		var argv = [''];     // arguments vector
		var argQL = [''];    // quoting level
		var argc = 0;        // arguments cursor
		var escape = false ; // escape flag
		for (var i=0; i<termref.lineBuffer.length; i++) {
			var ch= termref.lineBuffer.charAt(i);
			if (escape) {
				argv[argc] += ch;
				escape = false;
			}
			else if (this.escapeExpressions[ch]) {
				var v = this.escapeExpressions[ch](termref, i, ch, argQL[argc]);
				if (typeof v != 'undefined') argv[argc] += v;
			}
			else if (this.quoteChars[ch]) {
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
			else if (this.whiteSpace[ch]) {
				if (argQL[argc]) {
					argv[argc] += ch;
				}
				else if (argv[argc] != '') {
					argc++;
					argv[argc] = argQL[argc] = '';
				}
			}
			else if (this.singleEscapes[ch]) {
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
		termref.argv = argv;
		termref.argQL = argQL;
		termref.argc = 0;
	}
}

// eof