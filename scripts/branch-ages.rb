system "git fetch origin"
system "git remote prune origin"

branches = []
`git branch --list --remote "origin/*"`.split.each do |branch|
  author = `git show --format=%an -s #{branch}`.strip
  date = `git show --format=%ct -s #{branch}`.strip.to_i
  branches << [date, branch, author]
end
branches.sort!

authors = []
author_branches = Hash.new { |hash, key|
  authors << key
  hash[key] = []
}
branches.each do |date, branch, author|
  author_branches[author] << [date, branch]
end

authors.each do |name|
  puts name
  author_branches[name].each do |date, branch|
    days = (Time.now.to_i - date) / 60 / 60 / 24
    puts "#{days.to_s.rjust 5} days old: #{branch[7..-1]}"
  end
  puts
end
