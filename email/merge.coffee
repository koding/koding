fs = require "fs"
_ = require "underscore"

a = fs.readFileSync("../invitee-emails.txt",'utf8')
aa = a.split("\n")
b = fs.readFileSync("./launchrock.txt",'utf8')
bb = b.split("\n")
c = _.difference bb,aa

fs.writeFileSync './difference.txt',c.join("\n"),'utf8'