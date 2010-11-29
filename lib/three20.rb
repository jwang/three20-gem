require 'fileutils'
require 'three20/version'

module Three20
  # Your code goes here...
  autoload :UI,                  'three20/ui'
  
  class Three20Error < StandardError
    def self.status_code(code = nil)
      define_method(:status_code) { code }
    end
  end
  class PathError        < Three20Error; status_code(13) ; end
  class GitError         < Three20Error; status_code(11) ; end
  class DeprecatedError  < Three20Error; status_code(12) ; end
  class DslError         < Three20Error; status_code(15) ; end
  class InvalidOption    < Three20Error                  ; end
    
end
