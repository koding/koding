package verbalexpressions_test

import (
	"fmt"
	"github.com/VerbalExpressions/GoVerbalExpressions"
)

func ExampleVerbalExpression_Find() {
	s := "foo bar baz"
	v := verbalexpressions.New().Find("bar")
	fmt.Println(v.Test(s))
	// Output: true
}

func ExampleVerbalExpression_Captures() {
	s := `This should get barsystem and whatever...
And there, another barelement to fetch`
	// get "bar" followed by a word
	v := verbalexpressions.New().Anything().
		BeginCapture().
		Find("bar").Word().
		EndCapture()

	res := v.Captures(s)

	// walk results
	for _, element := range res {
		// i reprensent capture count and element is a
		// slice with captures (0 = global find, 1 = first capture)
		fmt.Printf("Global capture: %s\n", element[0])
		fmt.Printf("First capture: %s\n", element[1])
	}

	//Output:
	//Global capture: This should get barsystem
	//First capture: barsystem
	//Global capture: And there, another barelement
	//First capture: barelement

}

func ExampleVerbalExpression_Range() {
	s := "This 1 is 55 a TEST"
	v := verbalexpressions.New().Range("a", "z", 0, 9)
	res := v.Regex().FindAllString(s, -1)
	fmt.Println(res)
	//Output: [h i s 1 i s 5 5 a]

}

func ExampleVerbalExpression_Any() {

	s := "foo1 foo5 foobar"
	v := verbalexpressions.New().Find("foo").Any("1234567890").Regex().FindAllString(s, -1)
	fmt.Println(v)
	//Output: [foo1 foo5]
}

func ExampleVerbalExpression_Or() {
	s := "This is a foo and a bar there"
	v1 := verbalexpressions.New().Find("bar")
	v := verbalexpressions.New().
		Find("foo").
		Or(v1)

	fmt.Println(v.Regex().FindAllString(s, -1))
	//Output: [foo bar]
}

func ExampleVerbalExpression_Replace() {

	s := "We've got a red house"
	res := verbalexpressions.New().Find("red").Replace(s, "blue")
	fmt.Println(res)
	//Output: We've got a blue house
}

func ExampleVerbalExpression_AnythingBut() {

	s := "This is a simple test"
	v := verbalexpressions.New().AnythingBut("ie").Regex().FindAllString(s, -1)
	fmt.Println(v)
	//Output: [Th s  s a s mpl  t st]
}
