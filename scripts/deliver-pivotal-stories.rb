#!/usr/bin/env ruby

require "pivotal-tracker"

begin
  TRACKER_TOKEN = ENV["PIVOTAL_TOKEN"]
  PROJECTS      = ENV["PIVOTAL_PROJECTS"]

  if TRACKER_TOKEN.nil?
    throw "Error: expected non empty 'PIVOTAL_TOKEN' env variable."
  end

  if PROJECTS.nil?
    throw "Error: expected non empty 'PIVOTAL_PROJECTS' env variable."
  end

  PivotalTracker::Client.token = TRACKER_TOKEN
  PivotalTracker::Client.use_ssl = true

  PROJECTS.split(",").each do |project_id|
    project = PivotalTracker::Project.find(project_id)
    stories = project.stories.all(state: "finished", story_type: ["bug", "feature"])

    sandbox_tag = "sandbox-deployment"

    stories.each do | story |
      search_result = `git log --merges --grep "\##{story.id}" #{sandbox_tag}`
      if search_result.length > 0
        puts "Found #{story.id}, marking as delivered."

        story.notes.create(:text => "Delivered by sandbox deploy script.")
        story.update({"current_state" => "delivered"})
      else
        puts "Could not find #{story.id} in git repo."
      end
    end
  end
rescue => e
  puts "Error: #{e}"
  exit(0)  # exit without error so as to not break deploy
end
