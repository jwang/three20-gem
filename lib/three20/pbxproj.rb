require 'fileutils'
require 'pathname'
require 'logger'

module Three20

  class Pbxproj
    @@logger = Logger.new(STDOUT)
    @@logger.level = Logger::INFO
    
    # search .xcodeproj in the given path. If no path is provided, then searches the current path.
    def find_project_file (path = nil)

      current_dir = FileUtils.pwd

      unless path.nil?
        path = File.expand_path(path)
        FileUtils.cd path

      else
        path = FileUtils.pwd
      end

      @@logger.info "checking #{path} for .xcodeproj"

      projects = Dir.glob("*.xcodeproj")

      if projects.empty?
        @@logger.info "No XCode project was found in the #{path}"
        Raise XCodeError
      else
        @@logger.info "project: #{projects[0]} was found"
        @name = projects[0].split('.xcodeproj')[0]
        @target = projects[0].split('.xcodeproj')[0]
        @@logger.info "target: #{@target}  name: #{@name}"
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
      @@logger.info "proj_path #{@project_path}"
    end

    # Find the relative path between 2 paths, path2 is always the path to three20's install
    def relative_path(path1 = nil, path2)
      path2 = path2 << "/three20"

      unless path1.nil?
        path1 = File.expand_path(path1)
        @@logger.info "expanded path1 to: #{path1}"
        #FileUtils.cd path #File.expand_path(path)

      else
        path1 = FileUtils.pwd
      end

      @@logger.info "path1: #{path1} with path2: #{path2}"

      p1 = Pathname.new(path1)
      p2 = Pathname.new(path2)
      relative_path = p2.relative_path_from(p1.parent) # TODO adding .parent seems like a hack
      
      @@logger.info "the relative path is: #{relative_path}"
      @@logger.info "expanded: #{File.expand_path(relative_path)}"
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

    if @project_data.nil?
      if !File.directory?(path)
        @@logger.info("Couldn't find the project at this path: #{path}")
        return nil
      end
    end
    #return None

      @@logger.info "get_project_data"

      @project_data = nil

      xcode_project = path << "/" << project_name << "/project.pbxproj"
      @@logger.info "xcode_project = #{xcode_project}"

      #file = File.open(xcode_project, "rb")
      @project_data = File.open(xcode_project, 'r') { |f| f.read }
      #puts @project_data
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
          @@logger.error "This is fatal: Unable to find the build phases from your target at: "  # TODO - add path as a ivar
          #raise error?
          return nil
        end

        #(self._guid, buildPhases, ) = result.groups()
        # not sure what this line is supposed to do
        @@logger.info build_phases.to_s.index(' /*')
        idx = build_phases.to_s.index(' /*').to_i
        @guid = build_phases.to_s[0..idx-1]
        @@logger.info "guid: #{@guid}"
        
        # Get the build phases we care about. - Resources and Frameworks
        
        @@logger.info build_phases.to_s.index('buildPhases = (')
        @@logger.info build_phases.to_s.index(' /* Resources */,')
        build_idx = build_phases.to_s.index('buildPhases = (').to_i + 'buildPhases = ('.length
        res_idx = build_phases.to_s.index(' /* Resources */,').to_i

        #match = re.search('([A-Z0-9]+) \/\* Resources \*\/', buildPhases)
        unless res_idx == 0
          @@logger.info build_phases.to_s[build_idx..res_idx].strip
          @resources_guid = build_phases.to_s[build_idx..res_idx].strip
          #(self._resources_guid, ) = match.groups()
        else
          @resources_guid = nil
          @@logger.info "Couldn't find the Resources phase"
        end
        
        #match = re.search('([A-Z0-9]+) \/\* Frameworks \*\/', buildPhases)

        frameworks_idx = build_phases.to_s.index(/([A-Z0-9]+) \/\* Frameworks \*\//).to_i

        if frameworks_idx == 0
          @@logger.info "Couldn't find the Frameworks phase from: " #+self.path()
          @@logger.info "Please add a New Link Binary With Libraries Build Phase to your target"
          @@logger.info "Right click your target in the project, Add, New Build Phase,"
          @@logger.info " \"New Link Binary With Libraries Build Phase\""
          return nil
        end

        temp_frameworks = build_phases.to_s[frameworks_idx..build_phases.to_s.length]
        temp_idx = temp_frameworks.index(" /*").to_i        

        @frameworks_guid = temp_frameworks[0..temp_idx-1]
        #(self._frameworks_guid, ) = match.groups()
        #puts "project_data = #{@project_data}"
        # Get the dependencies
        re = "#{Regexp.escape(@guid)} \/\* #{Regexp.escape(@target)} \*\/ = {\n[ \t]+isa = PBXNativeTarget;(?:.|\n)+?dependencies = \(\n((?:[ \t]+[A-Z0-9]+ \/\* PBXTargetDependency \*\/,\n)*)[ \t]*\);\n"
        puts re.to_s
        result = re.match(@project_data)
        #result = re.search(re.escape(self._guid)+' \/\* '+re.escape(self.target)+' \*\/ = {\n[ \t]+isa = PBXNativeTarget;(?:.|\n)+?dependencies = \(\n((?:[ \t]+[A-Z0-9]+ \/\* PBXTargetDependency \*\/,\n)*)[ \t]*\);\n',project_data)
        #result = @project_data.match('([A-Z0-9]+) \/\* ' << @target.to_s << ' \*\/ = {\n[ \t]+isa = PBXNativeTarget;(?:.|\n)+?builddependencies = \(\n((?:[ \t]+[A-Z0-9]+ \/\* PBXTargetDependency \*\/,\n)*)[ \t]*\);\n')

        # TODO - need to find a dependency to test somewhere

        @@logger.info "result #{result}"
        if result.nil?
          @@logger.error "Unable to get dependencies from: "#+self.path()
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
          @@logger.error("Unable to get product guid from: "+self.path())
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
		#@project_data = self.get_project_data()
    re = '\/\* Begin PBXBuildFile section \*\/\n((?:.|\n)+?)\/\* End PBXBuildFile section \*\/'
    match = re.match(@project_data)
		#match = re.search('\/\* Begin PBXBuildFile section \*\/\n((?:.|\n)+?)\/\* End PBXBuildFile section \*\/', project_data)
    #frameworks_idx = build_phases.to_s.index(/([A-Z0-9]+) \/\* Frameworks \*\//).to_i
    
		if match.nil?
			@@logger.error("Couldn't find PBXBuildFile section.")
			return nil
    end

    puts match[0]
		#(subtext, ) = match.groups()
    subtext = match[0]
		buildfile_hash = nil

    re = "([A-Z0-9]+).+?fileRef = #{Regexp.escape(file_ref_hash)}"
		match = re.match(subtext)
		unless match.nil?
		#	(buildfile_hash, ) = match.groups()
      buildfile_hash = match[0]
			@@logger.info("This build file already exists: #{buildfile_has}")
    end
      
		if buildfile_hash.nil?
      re = '\/\* Begin PBXBuildFile section \*\/\n'
			match = re.match(project_data)
			buildfile_hash = default_guid
    end
			libfiletext = "\t\t#{buildfile_hash} /* #{name} in Frameworks */ = {isa = PBXBuildFile; fileRef = #{file_ref_hash} /* #{name} */; };\n"
			@project_data = @project_data[match.end(0)] + libfiletext + @project_data[match.end(0)]
      puts @project_data
		#self.set_project_data(project_data)

		  buildfile_hash
    end

    # Add a line to the PBXFileReference section.
    #
    # <default_guid> /* <name> */ = {isa = PBXFileReference; lastKnownFileType = "wrapper.<file_type>"; name = <name>; path = <rel_path>; sourceTree = <source_tree>; };
    #
    # Returns: <default_guid> if a line was added.
    # Otherwise, the existing guid is returned.
    def add_file_reference(name, file_type, default_guid, rel_path, source_tree)
		#project_data = self.get_project_data()

		fileref_hash = nil
    re = "([A-Z0-9]+) \/\* #{Regexp.escape(name)} \*\/ = \{isa = PBXFileReference; lastKnownFileType = \"wrapper.#{Regexp.escape(file_type)}; name = #{Regexp.escape(name)}; path = #{Regexp.escape(rel_path)};"
    match = re.match(@project_data)
		#match = re.search('([A-Z0-9]+) \/\* '+re.escape(name)+' \*\/ = \{isa = PBXFileReference; lastKnownFileType = "wrapper.'+file_type+'"; name = '+re.escape(name)+'; path = '+re.escape(rel_path)+';', project_data)
		if match
			@@logger.info("This file has already been added.")
		#	(fileref_hash, ) = match.groups()
		  fileref_hash = match[0]

		else
		  re = '\/\* Begin PBXFileReference section \*\/\n'
			#match = re.search('\/\* Begin PBXFileReference section \*\/\n', project_data)
      match = re.match(@project_data)
			if match.nil?
				@@logger.error("Couldn't find the PBXFileReference section.")
				return nil
      end
      fileref_hash = default_guid
    end

		#	pbxfileref = "\t\t"+fileref_hash+" /* "+name+" */ = {isa = PBXFileReference; lastKnownFileType = \"wrapper."+file_type+"\"; name = "+name+"; path = "+rel_path+"; sourceTree = "+source_tree+"; };\n"
		
		pbxfileref = "\t\t #{fileref_hash} /* #{name} */ = {isa = PBXFileReference; lastKnownFileType = \"wrapper.#{file_type}\"; name = #{name}; path = #{rel_path}; sourceTree = #{source_tree}; };\n"
		
		@project_data = project_data[match.end(0)] << pbxfileref << project_data[match.end(0)]
    puts @project_data
		#self.set_project_data(project_data)

		#return fileref_hash
		  fileref_hash
    end

    # Add a file to the given PBXGroup.
    #
    # <guid> /* <name> */,
    def add_file_to_group(name, guid, group)
		#project_data = self.get_project_data()

		#match = re.search('\/\* '+re.escape(group)+' \*\/ = \{\n[ \t]+isa = PBXGroup;\n[ \t]+children = \(\n((?:.|\n)+?)\);', project_data)
		#if not match:
			@@logger.error("Couldn't find the "+group+" children.")
		#	return False

		#(children,) = match.groups()
		#match = re.search(re.escape(guid), children)
		#if match:
			@@logger.info("This file is already a member of the "+name+" group.")
		#else:
		#	match = re.search('\/\* '+re.escape(group)+' \*\/ = \{\n[ \t]+isa = PBXGroup;\n[ \t]+children = \(\n', project_data)

		#	if not match:
				@@logger.error("Couldn't find the "+group+" group.")
		#		return False

		#	pbxgroup = "\t\t\t\t"+guid+" /* "+name+" */,\n"
		#	project_data = project_data[:match.end()] + pbxgroup + project_data[match.end():]

		#self.set_project_data(project_data)

		#return True
    end

    # Add a file to the Frameworks PBXGroup.
    #
    # <guid> /* <name> */,
    def add_file_to_frameworks(name, guid)
      #return self.add_file_to_group(name, guid, 'Frameworks')
    end

    # Add a file to the Resources PBXGroup.
    #
    # <guid> /* <name> */,
    def add_file_to_resources(name, guid)
      #return self.add_file_to_group(name, guid, 'Resources')
    end

    def add_file_to_phase(name, guid, phase_guid, phase)
      #project_data = self.get_project_data()

		#match = re.search(re.escape(phase_guid)+" \/\* "+re.escape(phase)+" \*\/ = {(?:.|\n)+?files = \(((?:.|\n)+?)\);", project_data)

		#if not match:
			@@logger.error("Couldn't find the "+phase+" phase.")
		#	return False

		#(files, ) = match.groups()

		#match = re.search(re.escape(guid), files)
		#if match:
			@@logger.info("The file has already been added.")
		#else:
		#	match = re.search(re.escape(phase_guid)+" \/\* "+phase+" \*\/ = {(?:.|\n)+?files = \(\n", project_data)
		#	if not match:
				@@logger.error("Couldn't find the "+phase+" files")
			#	return False

			#frameworktext = "\t\t\t\t"+guid+" /* "+name+" in "+phase+" */,\n"
			#project_data = project_data[:match.end()] + frameworktext + project_data[match.end():]

		#self.set_project_data(project_data)

		#return True
    end

	  def get_rel_path_to_products_dir
		#project_path = os.path.dirname(os.path.abspath(self.xcodeprojpath()))
		#build_path = os.path.join(os.path.join(os.path.dirname(Paths.src_dir), 'Build'), 'Products')
		#return relpath(project_path, build_path)
    end

	  def add_file_to_frameworks_phase(name, guid)
		#return self.add_file_to_phase(name, guid, self._frameworks_guid, 'Frameworks')
    end

	  def add_file_to_resources_phase(name, guid)
		#if self._resources_guid is None:
			@@logger.error("No resources build phase found in the destination project")
			@@logger.error("Please add a New Copy Bundle Resources Build Phase to your target")
			@@logger.error("Right click your target in the project, Add, New Build Phase,")
			@@logger.error("  \"New Copy Bundle Resources Build Phase\"")
		#	return False

		#return self.add_file_to_phase(name, guid, self._resources_guid, 'Resources')
    #end
    end

    def add_header_search_path (configuration)
		#project_path = os.path.dirname(os.path.abspath(self.xcodeprojpath()))
		#build_path = os.path.join(os.path.join(os.path.join(os.path.dirname(Paths.src_dir), 'Build'), 'Products'), 'three20')
		#rel_path = relpath(project_path, build_path)

		#return self.add_build_setting(configuration, 'HEADER_SEARCH_PATHS', '"'+rel_path+'"')
    end

    def add_build_setting(configuration, setting_name, value)
		#project_data = self.get_project_data()

		#match = re.search('\/\* '+configuration+' \*\/ = {\n[ \t]+isa = XCBuildConfiguration;\n[ \t]+buildSettings = \{\n((?:.|\n)+?)\};', project_data)
		#if not match:
		#	print "Couldn't find this configuration."
		#	return False

		#settings_start = match.start(1)
		#settings_end = match.end(1)

		#(build_settings, ) = match.groups()

		#match = re.search(re.escape(setting_name)+' = ((?:.|\n)+?);', build_settings)

		#if not match:
			# Add a brand new build setting. No checking for existing settings necessary.
		#	settingtext = '\t\t\t\t'+setting_name+' = '+value+';\n'

		#	project_data = project_data[:settings_start] + settingtext + project_data[settings_start:]
		#else:
			# Build settings already exist. Is there one or many?
		#	(search_paths,) = match.groups()
		#	if re.search('\(\n', search_paths):
				# Many
		#		match = re.search(re.escape(value), search_paths)
		#		if not match:
					# If value has any spaces in it, Xcode will split it up into
					# multiple entries.
		#			escaped_value = re.escape(value).replace(' ', '",\n[ \t]+"')
		#			match = re.search(escaped_value, search_paths)
		#			if not match:
		#				match = re.search(re.escape(setting_name)+' = \(\n', build_settings)

		#				build_settings = build_settings[:match.end()] + '\t\t\t\t\t'+value+',\n' + build_settings[match.end():]
		#				project_data = project_data[:settings_start] + build_settings + project_data[settings_end:]
		#	else:
				# One
		#		if search_paths != value:
		#			existing_path = search_paths
		#			path_set = '(\n\t\t\t\t\t'+value+',\n\t\t\t\t\t'+existing_path+'\n\t\t\t\t)'
		#			build_settings = build_settings[:match.start(1)] + path_set + build_settings[match.end(1):]
		#			project_data = project_data[:settings_start] + build_settings + project_data[settings_end:]

		#self.set_project_data(project_data)

		#return True
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
      #project_data = self.get_project_data()
		  #dep_data = dep.get_project_data()

		  #if project_data is None or dep_data is None:
  		#	return False

		  @@logger.info("\nAdding "+str(dep)+" to "+str(self))

		  #project_path = os.path.dirname(os.path.abspath(self.xcodeprojpath()))
		  #dep_path = os.path.abspath(dep.xcodeprojpath())
		  #rel_path = relpath(project_path, dep_path)

		  @@logger.info("")
		  @@logger.info("Project path:    "+project_path)
		  @@logger.info("Dependency path: "+dep_path)
		  @@logger.info("Relative path:   "+rel_path)

		  #tthash_base = self.get_hash_base(dep.uniqueid())

		###############################################
		  @@logger.info("")
		  @@logger.info("Step 1: Add file reference to the dependency...")

		  #self.set_project_data(project_data)
		  #pbxfileref_hash = self.add_filereference(dep._project_name+'.xcodeproj', 'pb-project', tthash_base+'0', rel_path, 'SOURCE_ROOT')
		  #project_data = self.get_project_data()

		  @@logger.info("Done: Added file reference: "+pbxfileref_hash)

		###############################################
		  @@logger.info("")
		  @@logger.info("Step 2: Add file to Frameworks group...")

		  #self.set_project_data(project_data)
		  #if not self.add_file_to_frameworks(dep._project_name+".xcodeproj", pbxfileref_hash):
			  #return False
		  #project_data = self.get_project_data()

		  @@logger.info("Done: Added file to Frameworks group.")

		###############################################
		  @@logger.info("")
		  @@logger.info("Step 3: Add dependencies...")

		  #pbxtargetdependency_hash = None
		  #pbxcontaineritemproxy_hash = None

		  #match = re.search('\/\* Begin PBXTargetDependency section \*\/\n((?:.|\n)+?)\/\* End PBXTargetDependency section \*\/', project_data)
		  #if not match:
			  @@logger.info("\tAdding a PBXTargetDependency section...")
			#  match = re.search('\/\* End PBXSourcesBuildPhase section \*\/\n', project_data)

			#if not match:
				@@logger.error("Couldn't find the PBXSourcesBuildPhase section.")
			#	return False

			#project_data = project_data[:match.end()] + "\n/* Begin PBXTargetDependency section */\n\n/* End PBXTargetDependency section */\n" + project_data[match.end():]
		  #else:
			#  (subtext, ) = match.groups()
			#match = re.search('([A-Z0-9]+) \/\* PBXTargetDependency \*\/ = {\n[ \t]+isa = PBXTargetDependency;\n[ \t]+name = '+re.escape(dep._project_name)+';\n[ \t]+targetProxy = ([A-Z0-9]+) \/\* PBXContainerItemProxy \*\/;', project_data)
			#if match:
			#	(pbxtargetdependency_hash, pbxcontaineritemproxy_hash,) = match.groups()
				@@logger.info("This dependency already exists.")

		#if pbxtargetdependency_hash is None or pbxcontaineritemproxy_hash is None:
		#	match = re.search('\/\* Begin PBXTargetDependency section \*\/\n', project_data)

		#	pbxtargetdependency_hash = tthash_base+'1'
		#	pbxcontaineritemproxy_hash = tthash_base+'2'

		#	pbxtargetdependency = "\t\t"+pbxtargetdependency_hash+" /* PBXTargetDependency */ = {\n\t\t\tisa = PBXTargetDependency;\n\t\t\tname = "+dep._project_name+";\n\t\t\ttargetProxy = "+pbxcontaineritemproxy_hash+" /* PBXContainerItemProxy */;\n\t\t};\n"
		#	project_data = project_data[:match.end()] + pbxtargetdependency + project_data[match.end():]

		@@logger.info("Done: Added dependency.")


		###############################################
		@@logger.info("")
	  @@logger.info("Step 3.1: Add container proxy for dependencies...")

		#containerExists = False

		#match = re.search('\/\* Begin PBXContainerItemProxy section \*\/\n((?:.|\n)+?)\/\* End PBXContainerItemProxy section \*\/', project_data)
		#if not match:
			@@logger.info("\tAdding a PBXContainerItemProxy section...")
		#	match = re.search('\/\* End PBXBuildFile section \*\/\n', project_data)

		#	if not match:
				@@logger.error("Couldn't find the PBXBuildFile section.")
		#		return False

		#	project_data = project_data[:match.end()] + "\n/* Begin PBXContainerItemProxy section */\n\n/* End PBXContainerItemProxy section */\n" + project_data[match.end():]
		#else:
		#	(subtext, ) = match.groups()
		#	match = re.search(re.escape(pbxcontaineritemproxy_hash), subtext)
		#	if match:
				@@logger.info("This container proxy already exists.")
		#		containerExists = True

		#if not containerExists:
		#	match = re.search('\/\* Begin PBXContainerItemProxy section \*\/\n', project_data)

		#	pbxcontaineritemproxy = "\t\t"+pbxcontaineritemproxy_hash+" /* PBXContainerItemProxy */ = {\n\t\t\tisa = PBXContainerItemProxy;\n\t\t\tcontainerPortal = "+pbxfileref_hash+" /* "+dep._project_name+".xcodeproj */;\n\t\t\tproxyType = 1;\n\t\t\tremoteGlobalIDString = "+dep.guid()+";\n\t\t\tremoteInfo = "+dep._project_name+";\n\t\t};\n"
		#	project_data = project_data[:match.end()] + pbxcontaineritemproxy + project_data[match.end():]

		@@logger.info("Done: Added container proxy.")


		###############################################
		@@logger.info("")
		@@logger.info("Step 3.2: Add module to the dependency list...")

		#match = re.search(self.guid()+' \/\* .+? \*\/ = {\n[ \t]+(?:.|\n)+?[ \t]+dependencies = \(\n((?:.|\n)+?)\);', project_data)

		#dependency_exists = False

		#if not match:
			@@logger.error("Couldn't find the dependency list.")
		#	return False
		#else:
		#	(dependencylist, ) = match.groups()
		#	match = re.search(re.escape(pbxtargetdependency_hash), dependencylist)
		#	if match:
				@@logger.info("This dependency has already been added.")
		#		dependency_exists = True

		#if not dependency_exists:
		#	match = re.search(self.guid()+' \/\* .+? \*\/ = {\n[ \t]+(?:.|\n)+?[ \t]+dependencies = \(\n', project_data)

		#	if not match:
				@@logger.error("Couldn't find the dependency list.")
		#		return False

		#	dependency_item = '\t\t\t\t'+pbxtargetdependency_hash+' /* PBXTargetDependency */,\n'
		#	project_data = project_data[:match.end()] + dependency_item + project_data[match.end():]

		@@logger.info("Done: Added module to the dependency list.")


		###############################################
		@@logger.info("")
		@@logger.info("Step 4: Create project references...")

		#match = re.search('\/\* Begin PBXProject section \*\/\n((?:.|\n)+?)\/\* End PBXProject section \*\/', project_data)
		#if not match:
			@@logger.error("Couldn't find the project section.")
		#	return False

		#project_start = match.start(1)
		#project_end = match.end(1)

		#(project_section, ) = match.groups()

		#reference_exists = False
		#did_change = False

		#productgroup_hash = None

		#match = re.search('projectReferences = \(\n((?:.|\n)+?)\n[ \t]+\);', project_section)
		#if not match:
			@@logger.info("Creating project references...")
		#	match = re.search('projectDirPath = ".*?";\n', project_section)
		#	if not match:
				@@logger.error("Couldn't find project references anchor.")
		#		return False

		#	did_change = True
		#	project_section = project_section[:match.end()] + '\t\t\tprojectReferences = (\n\t\t\t);\n' + project_section[match.end():]

		#else:
		#	(refs, ) = match.groups()

		#	match = re.search('\{\n[ \t]+ProductGroup = ([A-Z0-9]+) \/\* Products \*\/;\n[ \t]+ProjectRef = '+re.escape(pbxfileref_hash), refs)
		#	if match:
		#		(productgroup_hash, ) = match.groups()
				@@logger.info("This product group already exists: "+productgroup_hash)
		#		reference_exists = True


		#if not reference_exists:
		#	match = re.search('projectReferences = \(\n', project_section)

		#	if not match:
				@@logger.error("Missing the project references item.")
		#		return False

		#	productgroup_hash = tthash_base+'3'

		#	reference_text = '\t\t\t\t{\n\t\t\t\t\tProductGroup = '+productgroup_hash+' /* Products */;\n\t\t\t\t\tProjectRef = '+pbxfileref_hash+' /* '+dep._project_name+'.xcodeproj */;\n\t\t\t\t},\n'
		#	project_section = project_section[:match.end()] + reference_text + project_section[match.end():]
		#	did_change = True

		#if did_change:
		#	project_data = project_data[:project_start] + project_section + project_data[project_end:]

	  @@logger.info("Done: Created project reference.")

		###############################################
		@@logger.info("")
		@@logger.info("Step 4.1: Create product group...")

		#match = re.search('\/\* Begin PBXGroup section \*\/\n', project_data)
		#if not match:
			@@logger.error("Couldn't find the group section.")
		#	return False

		#group_start = match.end()

		#lib_hash = None

		#match = re.search(re.escape(productgroup_hash)+" \/\* Products \*\/ = \{\n[ \t]+isa = PBXGroup;\n[ \t]+children = \(\n((?:.|\n)+?)\);", project_data)
		#if match:
			@@logger.info("This product group already exists.")
		#	(children, ) = match.groups()
		#	match = re.search('([A-Z0-9]+) \/\* '+re.escape(dep._product_name)+' \*\/', children)
		#	if not match:
				@@logger.error("No product found")
		#		return False
				# TODO: Add this product.
		#	else:
		#		(lib_hash, ) = match.groups()

		#else:
		#	lib_hash = tthash_base+'4'

		#	productgrouptext = "\t\t"+productgroup_hash+" /* Products */ = {\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t"+lib_hash+" /* "+dep._product_name+" */,\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = \"<group>\";\n\t\t};\n"
		#	project_data = project_data[:group_start] + productgrouptext + project_data[group_start:]

		@@logger.info("Done: Created product group: "+lib_hash)



		###############################################
		@@logger.info("")
		@@logger.info("Step 4.2: Add container proxy for target product...")

		#containerExists = False

		#targetproduct_hash = tthash_base+'6'

		#match = re.search('\/\* Begin PBXContainerItemProxy section \*\/\n((?:.|\n)+?)\/\* End PBXContainerItemProxy section \*\/', project_data)
		#if not match:
			@@logger.info("\tAdding a PBXContainerItemProxy section...")
		#	match = re.search('\/\* End PBXBuildFile section \*\/\n', project_data)

		#	if not match:
				@@logger.error("Couldn't find the PBXBuildFile section.")
		#		return False

		#	project_data = project_data[:match.end()] + "\n/* Begin PBXContainerItemProxy section */\n\n/* End PBXContainerItemProxy section */\n" + project_data[match.end():]
		#else:
		#	(subtext, ) = match.groups()
		#	match = re.search(re.escape(targetproduct_hash), subtext)
		#	if match:
				@@logger.info("This container proxy already exists.")
		#		containerExists = True

		#if not containerExists:
		#	match = re.search('\/\* Begin PBXContainerItemProxy section \*\/\n', project_data)

		#	pbxcontaineritemproxy = "\t\t"+targetproduct_hash+" /* PBXContainerItemProxy */ = {\n\t\t\tisa = PBXContainerItemProxy;\n\t\t\tcontainerPortal = "+pbxfileref_hash+" /* "+dep._project_name+".xcodeproj */;\n\t\t\tproxyType = 2;\n\t\t\tremoteGlobalIDString = "+dep._product_guid+";\n\t\t\tremoteInfo = "+dep._project_name+";\n\t\t};\n"
		#	project_data = project_data[:match.end()] + pbxcontaineritemproxy + project_data[match.end():]

		@@logger.info("Done: Added target container proxy.")


		###############################################
		@@logger.info("")
		@@logger.info("Step 4.3: Create reference proxy...")

		#referenceExists = False

		#match = re.search('\/\* Begin PBXReferenceProxy section \*\/\n((?:.|\n)+?)\/\* End PBXReferenceProxy section \*\/', project_data)
		#if not match:
			@@logger.info("\tAdding a PBXReferenceProxy section...")
		#	match = re.search('\/\* End PBXProject section \*\/\n', project_data)

		#	if not match:
				@@logger.error("Couldn't find the PBXProject section.")
		#		return False

		#	project_data = project_data[:match.end()] + "\n/* Begin PBXReferenceProxy section */\n\n/* End PBXReferenceProxy section */\n" + project_data[match.end():]
		#else:
		#	(subtext, ) = match.groups()
		#	match = re.search(re.escape(lib_hash), subtext)
		#	if match:
				@@logger.info("This reference proxy already exists.")
		#		referenceExists = True

		#if not referenceExists:
		#	match = re.search('\/\* Begin PBXReferenceProxy section \*\/\n', project_data)

		#	referenceproxytext = "\t\t"+lib_hash+" /* "+dep._product_name+" */ = {\n\t\t\tisa = PBXReferenceProxy;\n\t\t\tfileType = archive.ar;\n\t\t\tpath = \""+dep._product_name+"\";\n\t\t\tremoteRef = "+targetproduct_hash+" /* PBXContainerItemProxy */;\n\t\t\tsourceTree = BUILT_PRODUCTS_DIR;\n\t\t};\n"
		#	project_data = project_data[:match.end()] + referenceproxytext + project_data[match.end():]

		@@logger.info("Done: Created reference proxy.")


		###############################################
		@@logger.info("")
		@@logger.info("Step 5: Add target file...")

		#self.set_project_data(project_data)
		#libfile_hash = self.add_buildfile(dep._product_name, lib_hash, tthash_base+'5')
		#project_data = self.get_project_data()

		@@logger.info("Done: Added target file.")


		###############################################
		@@logger.info("")
		@@logger.info("Step 6: Add frameworks...")

		#self.set_project_data(project_data)
		#self.add_file_to_frameworks_phase(dep._product_name, libfile_hash)
		#project_data = self.get_project_data()

		@@logger.info("Done: Adding module.")

		#self.set_project_data(project_data)

		#return True
    end

  end

end