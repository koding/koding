def get_version
  `git describe`.strip
end

def get_temp
  `mktemp -d -t tmpXXXXXX`.strip
end

def get_name
  'puppetlabs-cloud-provisioner'
end


namespace :package do

  desc "Create a release .tar.gz"
  task :tar => :build_environment do
    name = get_name
    rm_rf 'pkg/tar'
    temp=`mktemp -d -t tmpXXXXXX`.strip!
    version = `git describe`.strip!
    base = "#{temp}/#{name}-#{version}/"
    mkdir_p base
    sh "git checkout-index -af --prefix=#{base}"
    mkdir_p "pkg/tar"
    sh "tar -C #{temp} -p -c -z -f #{temp}/#{name}-#{version}.tar.gz #{name}-#{version}"
    mv "#{temp}/#{name}-#{version}.tar.gz",  "pkg/tar"
    rm_rf temp
    puts
    puts "Tarball is pkg/tar/#{name}-#{version}.tar.gz"
  end

  task :build_environment do
    unless ENV['FORCE'] == '1'
      modified = `git status --porcelain | sed -e '/^\?/d'`
      if modified.split(/\n/).length != 0
        puts <<-HERE
!! ERROR: Your git working directory is not clean. You must
!! remove or commit your changes before you can create a package:

#{`git status | grep '^#'`.chomp}

!! To override this check, set FORCE=1 -- e.g. `rake package:deb FORCE=1`
        HERE
        raise
      end
    end
  end

  # Return the file with the latest mtime matching the String filename glob (e.g. "foo/*.bar").
  def latest_file(glob)
    require 'find'
    return FileList[glob].map{|path| [path, File.mtime(path)]}.sort_by(&:last).map(&:first).last
  end

end
