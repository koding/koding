task :default => :spec

desc "run the specs"
task :spec do
  local_vows = "./node_modules/.bin/vows"
  vows = File.exist?(local_vows) ? local_vows : "vows"
  sh "#{vows} " + Dir.glob("spec/**/*_spec.js").join(" ")
end
