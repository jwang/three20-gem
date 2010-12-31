require 'fileutils'
require 'pathname'

module Three20

  class Pbxproj

    # search .xcodeproj in the given path. If no path is provided, then searches the current path.
    def find_project_file (path = nil)

      current_dir = FileUtils.pwd

      unless path.nil?
        path = File.expand_path(path)
        FileUtils.cd path #File.expand_path(path)

      else
        path = FileUtils.pwd
      end

      puts "checking #{path} for .xcodeproj"

      projects = Dir.glob("*.xcodeproj")

      if projects.empty?
        puts "No XCode project was found in the #{path}"
        Raise XCodeError
      else
        puts "project: #{projects[0]} was found"
      end

      FileUtils.cd current_dir

      self.xcodeproj_path(path)
      self.get_project_data(path,projects[0])
      projects[0]
      
    end

    # A pbxproj file is contained within an xcodeproj file.
    # This method simply strips off the project.pbxproj part of the path.
    def xcodeproj_path(proj_path = nil)
      @project_path = proj_path
      puts "proj_path #{@project_path}"
    end

    # Find the relative path between 2 paths, path2 is always the path to three20's install
    def relative_path(path1 = nil, path2)
      path2 = path2 << "/three20"

      unless path1.nil?
        path1 = File.expand_path(path1)
        puts "expanded path1 to: #{path1}"
        #FileUtils.cd path #File.expand_path(path)

      else
        path1 = FileUtils.pwd
      end

      puts "path1: #{path1} with path2: #{path2}"

      p1 = Pathname.new(path1)
      p2 = Pathname.new(path2)
      relative_path = p2.relative_path_from(p1.parent) # TODO adding .parent seems like a hack
      
      puts "the relative path is: #{relative_path}"
      puts "expanded: #{File.expand_path(relative_path)}"
    end

    # Load the project data from disk.
    def get_project_data(path, project_name)
    #if self._project_data is None:
    #if not os.path.exists(self.path()):
    #logging.info("Couldn't find the project at this path:")
    #logging.info(self.path())
    #return None
      @project_data = nil
      
      xcode_project = path << "/" << project_name << "/project.pbxproj"
      puts "xcode_project = #{xcode_project}"

      file = File.new(xcode_project, "r")

      counter = 1
      while (line = file.gets)
        puts "#{counter}: #{line}"
        #@project_data << line
        counter = counter + 1
      end
      file.close

      

    #project_file = open(self.path(), 'r')
    #self._project_data = project_file.read()

    
    end

    # Write the project data to disk.
    def set_project_data(project_data)

    #if self._project_data != project_data:
    #self._project_data = project_data
    #project_file = open(self.path(), 'w')
    #project_file.write(self._project_data)
    end


    # Get and cache the dependencies for this project.
    def dependencies


    end


    # Add a line to the PBXBuildFile section.
    #
    # <default_guid> /* <name> in Frameworks */ = {isa = PBXBuildFile; fileRef = <file_ref_hash> /* <name> */; };
    #
    # Returns: <default_guid> if a line was added.
    # Otherwise, the existing guid is returned.
    def add_build_file

    end

    # Add a line to the PBXFileReference section.
    #
    # <default_guid> /* <name> */ = {isa = PBXFileReference; lastKnownFileType = "wrapper.<file_type>"; name = <name>; path = <rel_path>; sourceTree = <source_tree>; };
    #
    # Returns: <default_guid> if a line was added.
    # Otherwise, the existing guid is returned.
    def add_file_reference

    end

    # Add a file to the given PBXGroup.
    #
    # <guid> /* <name> */,
    def add_file_to_group
      
    end

    # Add a file to the Frameworks PBXGroup.
    #
    # <guid> /* <name> */,
    def add_file_to_frameworks

    end

    # Add a file to the Resources PBXGroup.
    #
    # <guid> /* <name> */,
    def add_file_to_resources
      
    end

    def add_file_to_phase
      
    end


    def add_header_search_path (configuration)

    end

    def add_build_setting(configuration, setting_name, value)
      
    end

    def add_framework(framework)
      
    end

    def add_bundle
      
    end

    def add_dependency(dep)
      
    end

  end

end