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
        @name = projects[0].split('.xcodeproj')[0]
        @target = projects[0].split('.xcodeproj')[0]
        puts "target: #{@target}  name: #{@name}"
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

    # TODO - Fix this. giant ruby violation
    def __str__
      #str(self.name)+" target:"+str(self.target)+" guid:"+str(self._guid)+" prodguid: "+self._product_guid+" prodname: "+self._product_name
    end


    def uniqueid
      @name << ':' << @target
    end

    def guid
      if @guid.nil?
        self.dependencies
      end
      @guid
    end

    # Load the project data from disk.
    def get_project_data(path, project_name)
    #if self._project_data is None:
    #if not os.path.exists(self.path()):
    #logging.info("Couldn't find the project at this path:")
    #logging.info(self.path())
    #return None

      puts "get_project_data"

      @project_data = nil

      xcode_project = path << "/" << project_name << "/project.pbxproj"
      puts "xcode_project = #{xcode_project}"

      #file = File.open(xcode_project, "rb")
      @project_data = File.open(xcode_project, 'rb') { |f| f.read }
      #@project_data = file.sysread
      #counter = 1
      #while (line = file.gets)
      #  puts "#{counter}: #{line}"
      #  counter = counter + 1
      #end
      #file.close
      #s = IO.read(xcode_project)
      #puts "s = #{s}"


      #puts "project data #{@project_data}"

      self.dependencies

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
      if @deps.nil?

        # Get build phases
        build_phases = @project_data.match('([A-Z0-9]+) \/\* ' << @target.to_s << ' \*\/ = {\n[ \t]+isa = PBXNativeTarget;(?:.|\n)+?buildPhases = \(\n((?:.|\n)+?)\);')

        #puts "build_phases = #{build_phases}"

        if build_phases.nil?
          puts "This is fatal: Unable to find the build phases from your target at: "  # TODO - add path as a ivar
          #raise error?
          return nil
        end

        #(self._guid, buildPhases, ) = result.groups()
        # not sure what this line is supposed to do
        puts build_phases.to_s.index(' /*')
        idx = build_phases.to_s.index(' /*').to_i
        @guid = build_phases.to_s[0..idx-1]
        puts "guid: #{@guid}"
        
        # Get the build phases we care about. - Resources and Frameworks
        
        puts build_phases.to_s.index('buildPhases = (')
        puts build_phases.to_s.index(' /* Resources */,')
        build_idx = build_phases.to_s.index('buildPhases = (').to_i + 'buildPhases = ('.length
        res_idx = build_phases.to_s.index(' /* Resources */,').to_i

        #match = re.search('([A-Z0-9]+) \/\* Resources \*\/', buildPhases)
        unless res_idx == 0
          puts build_phases.to_s[build_idx..res_idx].strip
          @resources_guid = build_phases.to_s[build_idx..res_idx].strip
          #(self._resources_guid, ) = match.groups()
        else
          @resources_guid = nil
          puts "Couldn't find the Resources phase"
        end
        
        #match = re.search('([A-Z0-9]+) \/\* Frameworks \*\/', buildPhases)

        frameworks_idx = build_phases.to_s.index(/([A-Z0-9]+) \/\* Frameworks \*\//).to_i

        if frameworks_idx == 0
          puts "Couldn't find the Frameworks phase from: " #+self.path()
          puts "Please add a New Link Binary With Libraries Build Phase to your target"
          puts "Right click your target in the project, Add, New Build Phase,"
          puts " \"New Link Binary With Libraries Build Phase\""
          return nil
        end

        temp_frameworks = build_phases.to_s[frameworks_idx..build_phases.to_s.length]
        temp_idx = temp_frameworks.index(" /*").to_i        

        @frameworks_guid = temp_frameworks[0..temp_idx-1]
        #(self._frameworks_guid, ) = match.groups()

        # Get the dependencies
        #result = re.search(re.escape(self._guid)+' \/\* '+re.escape(self.target)+' \*\/ = {\n[ \t]+isa = PBXNativeTarget;(?:.|\n)+?dependencies = \(\n((?:[ \t]+[A-Z0-9]+ \/\* PBXTargetDependency \*\/,\n)*)[ \t]*\);\n',project_data)
        result = @project_data.match('([A-Z0-9]+) \/\* ' << @target.to_s << ' \*\/ = {\n[ \t]+isa = PBXNativeTarget;(?:.|\n)+?builddependencies = \(\n((?:[ \t]+[A-Z0-9]+ \/\* PBXTargetDependency \*\/,\n)*)[ \t]*\);\n')

        # TODO - need to find a dependency to test somewhere

        puts "result #{result}"
        if result.nil?
          puts "Unable to get dependencies from: "#+self.path()
          #return None
          return nil
        end
        
        #(dependency_set, ) = result.groups()
        #dependency_guids = re.findall('[ \t]+([A-Z0-9]+) \/\* PBXTargetDependency \*\/,\n', dependency_set)

        # Parse the dependencies
        dependency_names = []

        #for guid in dependency_guids:
        #  result = re.search(guid+' \/\* PBXTargetDependency \*\/ = \{\n[ \t]+isa = PBXTargetDependency;\n[ \t]*name = (["a-zA-Z0-9\.\-]+);', project_data)

        unless result.nil?
          #(dependency_name, ) = result.groups()
          #dependency_names.append(dependency_name)
        end

        @deps = dependency_names

        # Get the product guid and name.
        #result = re.search(re.escape(self._guid)+' \/\* '+re.escape(self.target)+' \*\/ = {\n[ \t]+isa = PBXNativeTarget;(?:.|\n)+?productReference = ([A-Z0-9]+) \/\* (.+?) \*\/;', project_data)

        if result.nil?
          #logging.error("Unable to get product guid from: "+self.path())
          #return None
        end

        #(self._product_guid, self._product_name, ) = result.groups()

      else
        @deps
      end
      @deps
    end


    # Add a line to the PBXBuildFile section.
    #
    # <default_guid> /* <name> in Frameworks */ = {isa = PBXBuildFile; fileRef = <file_ref_hash> /* <name> */; };
    #
    # Returns: <default_guid> if a line was added.
    # Otherwise, the existing guid is returned.
    def add_build_file(name, file_ref_hash, default_guid)

    end

    # Add a line to the PBXFileReference section.
    #
    # <default_guid> /* <name> */ = {isa = PBXFileReference; lastKnownFileType = "wrapper.<file_type>"; name = <name>; path = <rel_path>; sourceTree = <source_tree>; };
    #
    # Returns: <default_guid> if a line was added.
    # Otherwise, the existing guid is returned.
    def add_file_reference(name, file_type, default_guid, rel_path, source_tree)

    end

    # Add a file to the given PBXGroup.
    #
    # <guid> /* <name> */,
    def add_file_to_group(name, guid, group)
      
    end

    # Add a file to the Frameworks PBXGroup.
    #
    # <guid> /* <name> */,
    def add_file_to_frameworks(name, guid)

    end

    # Add a file to the Resources PBXGroup.
    #
    # <guid> /* <name> */,
    def add_file_to_resources(name, guid)
      
    end

    def add_file_to_phase(name, guid, phase_guid, phase)
      
    end


    def add_header_search_path (configuration)

    end

    def add_build_setting(configuration, setting_name, value)
      
    end

    def get_hash_base(uniquename)
      examplehash = '320FFFEEEDDDCCCBBBAAA000'
      #uniquehash = hashlib.sha224(uniquename).hexdigest().upper()
      #uniquehash = uniquehash[:len(examplehash) - 4]
      #'320'+uniquehash
    end

    def add_framework(framework)
      #tthash_base = self.get_hash_base(framework)
      #fileref_hash = self.add_filereference(framework, 'frameworks', tthash_base+'0', 'System/Library/Frameworks/'+framework, 'SDK_ROOT')
      #libfile_hash = self.add_buildfile(framework, fileref_hash, tthash_base+'1')

      #self.add_file_to_frameworks(framework, fileref_hash)

      #self.add_file_to_frameworks_phase(framework, libfile_hash)
      
    end

    def add_bundle
      #tthash_base = self.get_hash_base('Three20.bundle')
      #project_path = os.path.dirname(os.path.abspath(self.xcodeprojpath()))
      #build_path = os.path.join(Paths.src_dir, 'Three20.bundle')
      #rel_path = relpath(project_path, build_path)

      #fileref_hash = self.add_file_reference('Three20.bundle', 'plug-in', tthash_base+'0', rel_path, 'SOURCE_ROOT')

      #libfile_hash = self.add_build_file('Three20.bundle', fileref_hash, tthash_base+'1')

      #self.add_file_to_resources('Three20.bundle', fileref_hash)

      #self.add_file_to_resources_phase('Three20.bundle', libfile_hash)

    end

    def add_dependency(dep)
      
    end

  end

end