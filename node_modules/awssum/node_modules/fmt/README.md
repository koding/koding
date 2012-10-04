# fmt - Command Line Output Formatting #

## Example ##

```
var fmt = require('fmt');

fmt.sep();
fmt.title('The Truth about Cats');
fmt.field('Name', 'Felix');
fmt.field('Description', 'Regal. Mysterious with a wise look in her eyes.');
fmt.field('Legs', 4);
fmt.title('The Truth about Dogs');
fmt.field('Name', 'Fido');
fmt.field('Description', 'Bouncy. Out there, shiny, long brown coat.');
fmt.field('Legs', 2);
fmt.sep();
fmt.title('A List');
fmt.li('item 1');
fmt.li('the second item');
fmt.li('the third and final item');
fmt.separator();
```

Has the output:

```
===============================================================================
--- The Truth about Cats ------------------------------------------------------
Name                 : Felix
Description          : Regal. Mysterious with a wise look in her eyes.
Legs                 : 4
--- The Truth about Dogs ------------------------------------------------------
Name                 : Fido
Description          : Bouncy. Out there, shiny, long brown coat.
Legs                 : 2
===============================================================================
--- A List --------------------------------------------------------------------
* item 1
* the second item
* the third and final item
===============================================================================
```

## Usage ##

### fmt.separator() (alias: fmt.sep()) ###

Makes a double line on the screen which is 79 chars long.

e.g.

```
fmt.separator();
fmt.sep();

->

===============================================================================
```

### fmt.line() ###

Makes a line on the screen which is 79 chars long.

e.g.

```
fmt.line()

->

-------------------------------------------------------------------------------
```

### fmt.title(title) ###

Renders a title with three '-', then the title, then more (until the 79th char).

e.g.

```
fmt.title('The Truth about Cats');

->

--- The Truth about Cats ------------------------------------------------------
```

### fmt.field(key, value) ###

Renders a line with a key and then the value, but with the key padded to 20 chars so that each field lines up.

```
fmt.field('Name', 'Fido');
fmt.field('Description', 'Bouncy. Out there, shiny, long brown coat.');
fmt.field('Legs', 2);

->

Name                 : Fido
Description          : Bouncy. Out there, shiny, long brown coat.
Legs                 : 2
```

### fmt.subfield(key, value) ###

Renders a line with a key (preceded by '- ') and then the value, but with the key padded to 20 chars so that each field
lines up. This can be helpful when you have a field, then other fields related to that one.

e.g.

```
fs.stat(__filename, function(err, stats) {
    fmt.field('File', __filename);
    fmt.subfield('size', stats.size);
    fmt.subfield('uid', stats.uid);
    fmt.subfield('gid', stats.gid);
    fmt.subfield('ino', stats.ino);
    fmt.subfield('ctime', stats.ctime);
    fmt.subfield('mtime', stats.mtime);
});

->

File                 : /home/user/path/to/cats-and-dogs.js
- size               : 1003
- uid                : 1000
- gid                : 1000
- ino                : 17567406
- ctime              : Sun Aug 19 2012 17:08:52 GMT+1200 (NZST)
- mtime              : Sun Aug 19 2012 17:08:52 GMT+1200 (NZST)
```

### fmt.li(msg) ###

Prints the msg preceded with a '* ', so that it looks like a list.

e.g.

```
fmt.title('A List');
fmt.li('item 1');
fmt.li('the second item');
fmt.li('the third and final item');
fmt.line()

->

--- A List --------------------------------------------------------------------
* item 1
* the second item
* the third and final item
-------------------------------------------------------------------------------
```

### fmt.dump(data[, name]) ###

Prints a dump of the data, with the optional name beforehand. This is basically a shortcut for :
console.log(util.inspect(data, false, null, true));

e.g.

```
fs.stat(__filename, function(err, stats) {
    fmt.separator();
    fmt.title('Dump (with name)');
    fmt.dump(stats, 'stats');
    fmt.separator();
    fmt.title('Dump');
    fmt.dump(stats);
    fmt.separator();
});

->

===============================================================================
--- Dump (with name) ----------------------------------------------------------
stats : { dev: 2049,
  ino: 17567406,
  mode: 33188,
  nlink: 1,
  uid: 1000,
  gid: 1000,
  rdev: 0,
  size: 1025,
  blksize: 4096,
  blocks: 8,
  atime: Sun Aug 19 2012 17:28:54 GMT+1200 (NZST),
  mtime: Sun Aug 19 2012 17:28:51 GMT+1200 (NZST),
  ctime: Sun Aug 19 2012 17:28:51 GMT+1200 (NZST) }
===============================================================================
--- Dump ----------------------------------------------------------------------
{ dev: 2049,
  ino: 17567406,
  mode: 33188,
  nlink: 1,
  uid: 1000,
  gid: 1000,
  rdev: 0,
  size: 1025,
  blksize: 4096,
  blocks: 8,
  atime: Sun Aug 19 2012 17:28:54 GMT+1200 (NZST),
  mtime: Sun Aug 19 2012 17:28:51 GMT+1200 (NZST),
  ctime: Sun Aug 19 2012 17:28:51 GMT+1200 (NZST) }
===============================================================================
```

### fmt.msg(msg) ###

Prints the msg as-is! :)

e.g.

```
fmt.title('Example');
fmt.msg('Output as-is!');
fmt.line();

->

--- Example -------------------------------------------------------------------
Output as-is!
-------------------------------------------------------------------------------
```

# Author #

Written by [Andrew Chilton](http://chilts.org/) - [Blog](http://chilts.org/blog/) - [Twitter](https://twitter.com/andychilton).

# License #

MIT: [http://appsattic.mit-license.org/2012/](http://appsattic.mit-license.org/2012/)

(Ends)
