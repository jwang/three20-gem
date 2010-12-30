module Three20

  class Pbxproj

    # search .xcodeproj in the given path. If no path is provided, then searches the current path.
    def find_project_file (path = nil)
      
    end

    # A pbxproj file is contained within an xcodeproj file.
    # This method simply strips off the project.pbxproj part of the path.
    def xcodeproj_path
      
    end

    # Find the relative path between 2 paths
    def relpath(path1, path2)

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