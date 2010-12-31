require 'fileutils'
require 'pathname'
require 'rbconfig'
require 'three20/version'

module Three20
  # Your code goes here...
  
  THREE20_PATH = '~/.three20/'
  
  autoload :UI,                  'three20/ui'
  autoload :Pbxproj,             'three20/pbxproj'
  
  class Three20Error < StandardError
    def self.status_code(code = nil)
      define_method(:status_code) { code }
    end
  end
  class PathError        < Three20Error; status_code(13) ; end
  class GitError         < Three20Error; status_code(11) ; end
  class XCodeError       < Three20Error; status_code(14) ; end
  class DeprecatedError  < Three20Error; status_code(12) ; end
  class DslError         < Three20Error; status_code(15) ; end
  class InvalidOption    < Three20Error                  ; end
    
end
