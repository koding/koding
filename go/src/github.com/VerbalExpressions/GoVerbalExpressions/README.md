GoVerbalExpressions
===================

[![Build Status](https://drone.io/github.com/VerbalExpressions/GoVerbalExpressions/status.png)](https://drone.io/github.com/VerbalExpressions/GoVerbalExpressions/latest)
[![Coverage Status](https://coveralls.io/repos/VerbalExpressions/GoVerbalExpressions/badge.png?branch=master)](https://coveralls.io/r/VerbalExpressions/GoVerbalExpressions?branch=master)

Go VerbalExpressions implementation

VerbalExpression is a concept to help building difficult regular expressions.

See online doc here: http://godoc.org/github.com/VerbalExpressions/GoVerbalExpressions


## Other Implementations
You can see an up to date list of all ports on [VerbalExpressions.github.io](http://VerbalExpressions.github.io).
- [Javascript](https://github.com/jehna/VerbalExpressions)
- [Ruby](https://github.com/VerbalExpressions/RubyVerbalExpressions)
- [C#](https://github.com/VerbalExpressions/CSharpVerbalExpressions)
- [Python](https://github.com/VerbalExpressions/PythonVerbalExpressions)
- [Java](https://github.com/VerbalExpressions/JavaVerbalExpressions)
- [PHP](https://github.com/VerbalExpressions/PHPVerbalExpressions)
- [C++](https://github.com/VerbalExpressions/CppVerbalExpressions)
- [Haskell](https://github.com/VerbalExpressions/HaskellVerbalExpressions)


## Installation

Use this command line:
    
    go get github.com/VerbalExpressions/GoVerbalExpressions

This will install package in your $GOPATH and you will be ready to import it.

## Examples

```go

// import with a nice name
import (
    "github.com/VerbalExpressions/GoVerbalExpressions" // imports verbalexpressions package
    "fmt"
)

func main () {
    v := verbalexpressions.New().
            StartOfLine().
            Then("http").
            Maybe("s").
            Then( "://").
            Maybe("www.").
            AnythingBut(" ").
            EndOfLine()

    testMe := "https://www.google.com"
    
    if v.Test(testMe) {
       fmt.Println("You have a valid URL") 
    } else {
       fmt.Println("URL is incorrect") 
    }
}

```


We try to give alias method and/or helpers. For example:

```go

    // s will be "We have a blue house"
    s := verbalexpressions.New().Find("red").Replace("We have a red house", "blue")

    // c will be:
    // [
    //    ["http://www.google.com",  "http://", "www.google.com"]
    // ]
    c := verbalexpressions.New().
        BeginCapture().
            Find("http").Maybe("s").Find("://").
        EndCapture().
        BeginCapture().
            Find("www.").Anything().
        EndCapture().
        Captures("http://www.google.com")

    // check c[0][1] => http://
    //       c[0][2] => www.google.com

```


