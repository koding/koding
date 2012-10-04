// make wrapper so it would not mess the Windows installation

if (process.platform !== 'win32')
{
	var spawn = require('child_process').spawn;
	var make = spawn('/usr/bin/env', ['make', process.argv[2]]);
	make.stdout.on('data', function (data) {
		process.stdout.write(data);
	});
	make.stderr.on('data', function (data) {
		process.stderr.write(data);
	});
	make.on('exit', function (code) {
		process.exit(code);
	});
}
