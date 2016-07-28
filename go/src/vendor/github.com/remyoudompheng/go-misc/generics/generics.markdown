# What do people want?

## Parametric polymorphism in function signatures

Writing a function once and use it for many types.

    // for all T
    func reverse(slice []T) []T {
        rev := make([]T, len(slice))
        for i, x := range slice {
            rev[len(rev)-1-i] = x
        }
        return rev
    }

    var x []int
    x = reverse(x) // legal
    var y []string
    y = reverse(y) // legal

## Parametric polymorphism for types

Writing a type definition once and obtain a whole
family of types.

    // for all T
    type Tree[T] struct {
        Data  T
        Left  *Tree[T]
        Right *Tree[T]
    }

Requirement: define a syntax for the type parameter.

## Covariance

Convertibility of `T[A]` to `T[B]` if A is convertible to B
(or assignability). The issues arises for builtin
parameterized types (convertibility of []int to `[]interface{}`),
or user-defined parameterised types (`Tree[int] -> Tree[interface{}]`).

Similar issues about contravariance: `func(interface{}) -> func(int)`.

## Generic sorting

Through type classes and covariance:

    type Comparable typeclass {
        func Less(?, ?) bool
    }

    // for all Comparable T
    func Sort(slice []T) {
        for i := 0; i < len(slice); i++ {
            for j := 1; j < len(slice); j++ {
                if Comparable.Less(slice[j], slice[j-1]) {
                    slice[j], slice[j-1] = slice[j-1], slice[j]
                }
            }
        }
    }

Through polymorphism:

    // for all T
    func Sort(slice []T, less func(T, T) bool) {
        for i := 0; i < len(slice); i++ {
            for j := 1; j < len(slice); j++ {
                if less(slice[j], slice[j-1]) {
                    slice[j], slice[j-1] = slice[j-1], slice[j]
                }
            }
        }
    }

Also, some people want operator overloading.

Also, some people want polymorphic operators:

    // for all number types T
    func Sum(a, b T) T { return a + b }

## Other things

- Type classes.
- ...

# Specification annoyances

## Rules for parameterised types

Parameterised named types may follow the usual assignment rules of named
types: Tree[T] is not assignable to Tree[U], for coherence with builtin
parameterised types.

This is incompatible with people wanting covariance.

# Alternatives to full polymorphism

## Specializable packages

In this proposal, packages may use a placeholder identifier to designate
a type, and can generate at compile time a specialized version of
themselves where the placeholder is replaced by a particular type.

This approach was used for package `container/vector`, and can be found
in the external tool `gotgo`. Specialization is easily done through
lexical transformation of code.

The advantage is that the language rules need very little change to
include this concept.

The drawback is that combining generic data structures coming from
different packages may turn out to be impossible due to cyclical imports.

This approach exists in Ada.

# Implementation strategies

## Compile-time instantiation

Uses of a generic function produces executable code for each
possible type parameter.

    func reverse([]T) []T

is compiled to:

    reverse_int
    reverse_struct1
    reverse_struct2
    ...

Advantages: no performance hit at runtime.

Issues:

- executable size may blow up if functions get multiple type parameters.
- if the generic function is imported, the body must be available for
  instantiation.
- if an imported generic function `pkg1.F` uses a generic `pkg2.G`, where
  pkg1 imports pkg2, the body `pkg2.G` must be available, leading to
  include complexity explosion.

## Run-time usage of type information

The compiler performs type-checking but generic functions are compiled
into a single portion of code that receives type information as an extra
argument.

Advantages: no complexity explosion at compile time.

Issues: using type information at runtime slows down many operations,
like assignment of value types, which is probably done using memmove.
