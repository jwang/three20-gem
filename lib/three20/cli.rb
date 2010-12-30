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
      Install will install the Three20 Source code to the passed in path or system path.

      Passing [DIR] to install (e.g. vendor) will cause the Three20 source to be installed
      into the [DIR] directory rather than into system path.

      If the source has already been installed, three20 will tell you so and then exit.
    D
    method_option "path", :type => :string, :banner =>
      "Specify a different path than the system default ($BUNDLE_PATH or $GEM_HOME). Bundler will remember this value for future installs on this machine"
    method_option "system", :type => :boolean, :banner =>
      "Install to the system location ($BUNDLE_PATH or $GEM_HOME) even if the bundle was previously installed somewhere else for this application"

    def install(path = nil)
      puts "install"
      git_binary = "/usr/bin/env git"
      ret, err = '', ''

      current_dir = FileUtils.pwd
      puts current_dir

      if path.nil?
        puts "Installing to system path #{File.expand_path(THREE20_PATH, __FILE__)}"
        FileUtils.mkdir_p File.expand_path(THREE20_PATH, __FILE__)
      else
        puts "Installing to path #{File.expand_path(path, __FILE__)}"
        FileUtils.mkdir_p File.expand_path(path, __FILE__)
      end
      

      # create the ~/.three20 directory in the user's home
      FileUtils.mkdir_p File.expand_path("~/.three20", __FILE__)
      FileUtils.cd File.expand_path("~/.three20", __FILE__)

      # write path to file in .three20/config_file
      config_file = File.new("config_file", "w")
      config_file.write(File.expand_path("~/.three20", __FILE__).to_s)
      config_file.close

      #"git clone git://github.com/facebook/three20.git"
      Open3.popen3("git clone git://github.com/facebook/three20.git") do |stdin, stdout, stderr|
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

      if path.nil?
        FileUtils.cd File.expand_path("~/.three20", __FILE__)
        File.open('config_file', 'r') do |f1|
        while line = f1.gets
          puts line
          path = line + "/three20"
         end
        end
      end

      current_dir = FileUtils.pwd
      puts current_dir
      
      FileUtils.cd File.expand_path(path, __FILE__)

      Open3.popen3("git update") do |stdin, stdout, stderr|
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
    end
    
    desc "new", "Create a new XCode project with Three20 built in at the current path or the path to a given"
    long_desc <<-D
      Create a new XCode project with Three20 built in at the current path or the path to a given
    D
    def new(path = nil)
      puts "show"
    end
    
    desc "version", "Prints the three20 gem's version information"
    def version
      puts "Three20 gem version #{Three20::VERSION}"
    end
    map %w(-v --version) => :version
    
    desc "add", "Add Three20 to a project at the current path or given path"
    def add (path = nil)
      puts "add"
    end
    
    desc "remove", "Removes Three20 from the project at the current path or given path"
    def remove (path = nil)
      puts "remove"
    end
    
    desc "uninstall", "Removes Three20 from the installed path"
    def uninstall (path = nil)
      puts "uninstalling three20"
      three20_path = nil
      FileUtils.cd File.expand_path("~/.three20", __FILE__)
      File.open('config_file', 'r') do |f1|
         while line = f1.gets  
           puts line
           three20_path = line
         end  
       end

      FileUtils.rm_rf File.expand_path(three20_path, __FILE__)
      
    end
    
    desc "help", "Prints the Three20's version information"
    def help(cli = nil)
      puts "help"
    end   
  end
end