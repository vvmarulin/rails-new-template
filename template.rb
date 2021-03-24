# frozen_string_literal: true

# Run code from the lib folder that makes all the generation of new rails app
def apply_lib_template
  open_lib_folder
  apply('rails_new_template.rb')
  apply_rails_new_template
end

# Find lib folder of the current repository and add it to require path
def open_lib_folder
  remote = __FILE__ =~ %r{\Ahttps?://}
  template_folder_path = remote ? clone_template_repository : File.expand_path(__dir__)
  lib_folder_path = File.join(template_folder_path, 'lib')
  source_paths.unshift(lib_folder_path)
end

# Downloads current repositroy from the remote and returns the path to the dir
def clone_template_repository
  require 'shellwords'
  require 'tmpdir'

  tempdir = Dir.mktmpdir('rails-template-')
  at_exit { FileUtils.remove_entry(tempdir) }
  git clone: [
    '--quiet',
    'https://github.com/vvmarulin/rails-new-template.git',
    tempdir
  ].map(&:shellescape).join(' ')
  tempdir
end

apply_lib_template
