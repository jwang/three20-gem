require 'thor'
require 'thor/actions'
require 'fileutils'
require 'open3'
#require 'rubygems/config_file'

#Gem.configuration

module Three20
  class CLI < Thor
    include Thor::Actions
    include Open3
    
    def initialize(*)
      super
      the_shell = (options["no-color"] ? Thor::Shell::Basic.new : shell)
      #Three20.ui = UI::Shell.new(the_shell)
      #Three20.ui.debug! if options["verbose"]
      #Gem::DefaultUserInteraction.ui = UI::RGProxy.new(Bundler.ui)
    end   
    
    #default_task :install
    
    desc "install", "Install the current environment to the system"
    long_desc <<-D
      Install will install all of the gems in the current bundle, making them available
      for use. In a freshly checked out repository, this command will give you the same
      gem versions as the last person who updated the Gemfile and ran `bundle update`.

      Passing [DIR] to install (e.g. vendor) will cause the unpacked gems to be installed
      into the [DIR] directory rather than into system gems.

      If the bundle has already been installed, bundler will tell you so and then exit.
    D
    method_option "path", :type => :string, :banner =>
      "Specify a different path than the system default ($BUNDLE_PATH or $GEM_HOME). Bundler will remember this value for future installs on this machine"
    method_option "system", :type => :boolean, :banner =>
      "Install to the system location ($BUNDLE_PATH or $GEM_HOME) even if the bundle was previously installed somewhere else for this application"

    def install(path = nil)
      puts "install"
      git_binary = "/usr/bin/env git"
      ret, err = '', ''
      Open3.popen3("git status") do |stdin, stdout, stderr|
        #p stdin.read
        p stdout.read
        #Timeout.timeout(10) do
          while tmp = stdout.read(1024)
            ret += tmp
            if (@bytes_read += tmp.size) > 5242880
              bytes = @bytes_read
              @bytes_read = 0
              #raise GitTimeout.new(command, bytes)
            end
          end
        #end

        while tmp = stderr.read(1024)
          err += tmp
        end
      end
            
      #target = File.join(Dir.pwd, name)
      #FileUtils.mkdir_p(File.join(target, 'lib', name))
    end
    
    desc "update", "update the current environment"
    long_desc <<-D
      Update will install the newest versions of the gems listed in the Gemfile. Use
      update when you have changed the Gemfile, or if you want to get the newest
      possible versions of the gems in the bundle.
    D
    method_option "source", :type => :array, :banner => "Update a specific source (and all gems associated with it)"
    def update(path = nil)
      puts "update"
    end
    
    desc "show [GEM]", "Shows all gems that are part of the bundle, or the path to a given gem"
    long_desc <<-D
      Show lists the names and versions of all gems that are required by your Gemfile.
      Calling show with [GEM] will list the exact location of that gem on your machine.
    D
    def show(gem_name = nil)
      puts "show"
    end
    
    desc "version", "Prints the bundler's version information"
    def version
      puts "Three20 gem version #{Three20::VERSION}"
    end
    map %w(-v --version) => :version
    
    desc "add", "Prints the bundler's version information"
    def add (path = nil)
      puts "add"
    end
    
    desc "remove", "Prints the bundler's version information"
    def remove (path = nil)
      puts "remove"
    end
    
    desc "uninstall", "Prints the bundler's version information"
    def uninstall (path = nil)
      puts "uninstall"
    end
    
    desc "help", "Prints the bundler's version information"
    def help(cli = nil)
      puts "help"
    end   
  end
end