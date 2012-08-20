---
title: Filters API | ldapjs
markdown2extras: wiki-tables
logo-color: green
logo-font-family: google:Aldrich, Verdana, sans-serif
header-font-family: google:Aldrich, Verdana, sans-serif
---

# ldapjs Filters API

This document covers the ldapjs filters API and assumes that you are familiar
with LDAP. If you're not, read the [guide](http://ldapjs.org/guide.html) first.

LDAP search filters are really the backbone of LDAP search operations, and
ldapjs tries to get you in "easy" with them if your dataset is small, and also
lets you introspect them if you want to write a "query planner".  For reference,
make sure to read over [RFC2254](http://www.ietf.org/rfc/rfc2254.txt), as this
explains the LDAPv3 text filter representation.

ldapjs gives you a distinct object type mapping to each filter that is
context-sensitive. However, _all_ filters have a `matches()` method on them, if
that's all you need.  Most filters will have an `attribute` property on them,
since "simple" filters all operate on an attribute/value assertion.  The
"complex" filters are really aggregations of other filters (i.e. 'and'), and so
these don't provide that property.

All Filters in the ldapjs framework extend from `Filter`, which wil have the
property `type` available; this will return a string name for the filter, and
will be one of:

||equal||an `EqualityFilter`||
||present||a `PresenceFilter`||
||substring||a `SubstringFilter`||
||ge||a `GreaterThanEqualsFilter`||
||le||a `LessThanEqualsFilter`||
||and||an `AndFilter`||
||or||an `OrFilter`||
||not||a `NotFilter`||
||approx||an `ApproximateMatchFilter` (quasi-supported in ldapjs)||
||ext||an `ExtensibleMatchFilter` (not supported in ldapjs)||

# parseFilter(filterString)

Parses an [RFC2254](http://www.ietf.org/rfc/rfc2254.txt) filter string into an
ldapjs object(s).  If the filter is "complex", it will be a "tree" of objects.
For example:

    var parseFilter = require('ldapjs').parseFilter;

    var f = parseFilter('(objectclass=*)');

Is a "simple" filter, and would just return a `PresenceFilter` object. However,

    var f = parseFilter('(&(employeeType=manager)(l=Seattle))');

Would return an `AndFilter`, which would have a `filters` array of two
`EqualityFilter` objects.

`parseFilter` will throw if an invalid string is passed in (that is, a
syntactically invalid string). All filter objects in th

# EqualityFilter

The equality filter is used to check exact matching of attribute/value
assertions.  This object will have an `attribute` and `value` property, and the
`name` proerty will be `equal`.

The string syntax for an equality filter is `(attr=value)`.

The `matches()` method will return true IFF the passed in object has a
key matching `attribute` and a value matching `value`.

    var f = new EqualityFilter({
      attribute: 'cn',
      value: 'foo'
    });

    f.matches({cn: 'foo'});  => true
    f.matches({cn: 'bar'});  => false

Equality matching uses "strict" type JavaScript comparison, and by default
everything in ldapjs (and LDAP) is a UTF-8 string.  If you want comparison
of numbers, or something else, you'll need to use a middleware interceptor
that transforms values of objects.

# PresenceFilter

The presence filter is used to check if an object has an attribute at all, with
any value. This object will have an `attribute` property, and the `name`
property will be `present`.

The string syntax for a presence filter is `(attr=*)`.

The `matches()` method will return true IFF the passed in object has a
key matching `attribute`.

    var f = new PresenceFilter({
      attribute: 'cn'
    });

    f.matches({cn: 'foo'});  => true
    f.matches({sn: 'foo'});  => false

# SubstringFilter

The substring filter is used to do wildcard matching of a string value. This
object will have an `attribute` property and then it will have an `initial`
property, which is the prefix match, an `any` which will be an array of strings
that are to be found _somewhere_ in the target string, and a `final` property,
which will be the suffix match of the string. `any` and `final` are both
optional. The `name` property will be `substring`.

The string syntax for a presence filter is `(attr=foo*bar*cat*dog)`, which would
map to:

    {
      initial: 'foo',
      any: ['bar', 'cat'],
      final: 'dog'
    }

The `matches()` method will return true IFF the passed in object has a
key matching `attribute` and the "regex" matches the value

    var f = new SubstringFilter({
      attribute: 'cn',
      initial: 'foo',
      any: ['bar'],
      final: 'baz'
    });

    f.matches({cn: 'foobigbardogbaz'});  => true
    f.matches({sn: 'fobigbardogbaz'});  => false

# GreaterThanEqualsFilter

The ge filter is used to do comparisons and ordering based on the value type. As
mentioned elsewhere, by default everything in LDAP and ldapjs is a string, so
this filter's `matches()` would be using lexicographical ordering of strings.
If you wanted `>=` semantics over numeric values, you would need to add some
middleware to convert values before comparison (and the value of the filter).
Note that the ldapjs schema middleware will do this.

The GreaterThanEqualsFilter will have an `attribute` property, a `value`
property and the `name` property will be `ge`.

The string syntax for a ge filter is:

    (cn>=foo)

The `matches()` method will return true IFF the passed in object has a
key matching `attribute` and the value is `>=` this filter's `value`.

    var f = new GreaterThanEqualsFilter({
      attribute: 'cn',
      value: 'foo',
    });

    f.matches({cn: 'foobar'});  => true
    f.matches({cn: 'abc'});  => false

# LessThanEqualsFilter

The le filter is used to do comparisons and ordering based on the value type. As
mentioned elsewhere, by default everything in LDAP and ldapjs is a string, so
this filter's `matches()` would be using lexicographical ordering of strings.
If you wanted `<=` semantics over numeric values, you would need to add some
middleware to convert values before comparison (and the value of the filter).
Note that the ldapjs schema middleware will do this.

The string syntax for a le filter is:

    (cn<=foo)

The LessThanEqualsFilter will have an `attribute` property, a `value`
property and the `name` property will be `le`.

The `matches()` method will return true IFF the passed in object has a
key matching `attribute` and the value is `<=` this filter's `value`.

    var f = new LessThanEqualsFilter({
      attribute: 'cn',
      value: 'foo',
    });

    f.matches({cn: 'abc'});  => true
    f.matches({cn: 'foobar'});  => false

# AndFilter

The and filter is a complex filter that simply contains "child" filters. The
object will have a `filters` property which is an array of `Filter` objects. The
`name` property will be `and`.

The string syntax for an and filter is (assuming below we're and'ing two
equality filters):

    (&(cn=foo)(sn=bar))

The `matches()` method will return true IFF the passed in object matches all
the filters in the `filters` array.

    var f = new AndFilter({
      filters: [
        new EqualityFilter({
          attribute: 'cn',
          value: 'foo'
        }),
        new EqualityFilter({
          attribute: 'sn',
          value: 'bar'
        })
      ]
    });

    f.matches({cn: 'foo', sn: 'bar'});  => true
    f.matches({cn: 'foo', sn: 'baz'});  => false

# OrFilter

The or filter is a complex filter that simply contains "child" filters. The
object will have a `filters` property which is an array of `Filter` objects. The
`name` property will be `or`.

The string syntax for an or filter is (assuming below we're or'ing two
equality filters):

    (|(cn=foo)(sn=bar))

The `matches()` method will return true IFF the passed in object matches *any*
of the filters in the `filters` array.

    var f = new OrFilter({
      filters: [
        new EqualityFilter({
          attribute: 'cn',
          value: 'foo'
        }),
        new EqualityFilter({
          attribute: 'sn',
          value: 'bar'
        })
      ]
    });

    f.matches({cn: 'foo', sn: 'baz'});  => true
    f.matches({cn: 'bar', sn: 'baz'});  => false

# NotFilter

The not filter is a complex filter that contains a single "child" filter. The
object will have a `filter` property which is an instance of a `Filter` object.
The `name` property will be `not`.

The string syntax for a not filter is (assuming below we're not'ing an
equality filter):

    (!(cn=foo))

The `matches()` method will return true IFF the passed in object does not match
the filter in the `filter` property.

    var f = new NotFilter({
      filter: new EqualityFilter({
          attribute: 'cn',
          value: 'foo'
        })
    });

    f.matches({cn: 'bar'});  => true
    f.matches({cn: 'foo'});  => false

# ApproximateFilter

The approximate filter is used to check "approximate" matching of
attribute/value assertions.  This object will have an `attribute` and
`value` property, and the `name` proerty will be `approx`.

As a side point, this is a useless filter. It's really only here if you have
some whacky client that's sending this.  It just does an exact match (which
is what ActiveDirectory does too).

The string syntax for an equality filter is `(attr~=value)`.

The `matches()` method will return true IFF the passed in object has a
key matching `attribute` and a value exactly matching `value`.

    var f = new ApproximateFilter({
      attribute: 'cn',
      value: 'foo'
    });

    f.matches({cn: 'foo'});  => true
    f.matches({cn: 'bar'});  => false

