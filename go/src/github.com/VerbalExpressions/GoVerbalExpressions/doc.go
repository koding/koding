/*
This is a Go implementation of VerbalExpressions for other languages.
Check http://VerbalExpressions.github.io to know the other implementations.

VerbalExperssions is a way to build complex regular expressions with a verbal language.

The repo name is "GoVerbalExpressions" but the real package name is "verbalexpressions". So, to import verbalexpressions package, just do:

	import "github.com/VerbalExpressions/GoVerbalExpressions"

Then, use "verbalexpressions" as prefix. There is a simple example

Use "New()" factory then you can chain calls. Go syntax allows you to set new line after seperators:

	v := verbalexpressions.New().
		StartOfLine().
		Find("foo").
		Word().
		Anything().
		EndOfLine()

Then, you can use "Test()" method to check if your string matches expression.

You may get the regexp.Regexp structure using "Regex()" method, then use common methods to split, replace, find submatches and so on... as usual

There are some helpers that use direct call to the regexp package:

- Replace
- Captures
- Test

*/
package verbalexpressions
