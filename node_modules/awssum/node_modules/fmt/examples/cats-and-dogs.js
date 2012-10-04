var fs = require('fs');
var fmt = require('../fmt.js');

fmt.sep();

fmt.title('The Truth about Cats');
fmt.field('Name', 'Felix');
fmt.field('Description', 'Regal. Mysterious with a wise look in her eyes.');
fmt.field('Legs', 4);

fmt.line()
fmt.title('The Truth about Dogs');
fmt.field('Name', 'Fido');
fmt.field('Description', 'Bouncy. Out there, shiny, long brown coat.');
fmt.field('Legs', 2);

fmt.separator();

fmt.title('A List');
fmt.li('item 1');
fmt.li('the second item');
fmt.li('the third and final item');

fmt.separator();

fmt.title('Example');
fmt.msg('Output as-is!');

fmt.separator();

fs.stat(__filename, function(err, stats) {
    fmt.field('File', __filename);
    fmt.subfield('size', stats.size);
    fmt.subfield('uid', stats.uid);
    fmt.subfield('gid', stats.gid);
    fmt.subfield('ino', stats.ino);
    fmt.subfield('ctime', stats.ctime);
    fmt.subfield('mtime', stats.mtime);

    fmt.separator();

    fmt.title('Dump (with name)');
    fmt.dump(stats, 'stats');

    fmt.separator();

    fmt.title('Dump');
    fmt.dump(stats);

    fmt.separator();
});
