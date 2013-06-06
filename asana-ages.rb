#!/usr/bin/env ruby

require "rubygems"
require "JSON"
require "net/https"
require "set"
require "time"

api_key = "1CiFa7kf.0Hi53vqTnYUtH1iZ7Bw6Kiv"
workspace_id = "1030072787354"
assignee = "neelance@gmail.com"

http = Net::HTTP.new "app.asana.com", 443
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER

tasks = []
http.start { |http|
  do_request = lambda { |path|
    req = Net::HTTP::Get.new "/api/1.0/#{path}"
    req.basic_auth api_key, ''
    res = http.request req
    JSON.parse(res.body)["data"]
  }

  task_ids = Set.new
  do_request.call("workspaces/1030072787354/projects").each do |project|
    info = do_request.call("projects/#{project['id']}")
    next if info["archived"]
    do_request.call("projects/#{project['id']}/tasks").each do |ref|
      task_ids << ref["id"]
    end
  end

  task_ids.each_with_index do |id, i|
    task = do_request.call "tasks/#{id}"
    tasks << [Time.parse(task["modified_at"]).to_i, i, task] unless task["completed"]
    print "\e[G#{i * 100 / task_ids.size}%"
  end
}

tasks.sort!
assignees = []
assignee_tasks = Hash.new { |hash, key|
  assignees << key
  hash[key] = []
}
tasks.each do |date, _, task|
  assignee = task["assignee"] || { "name" => "Not assigned" }
  assignee_tasks[assignee["name"]] << [date, task]
end

print "\e[G"
assignees.each do |name|
  puts name
  assignee_tasks[name].each do |date, task|
    days = (Time.now.to_i - date) / 60 / 60 / 24
    puts "#{days.to_s.rjust 5} days old: #{task['name']} [#{task['projects'].map{ |project| project['name'] }.join(', ')}]"
  end
  puts
end
