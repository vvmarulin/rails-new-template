# frozen_string_literal: true

require 'bundler'
require 'json'

def apply_template!
  assert_default_rails_setup
  download_rails_template
  skip_packages_installation
  copy_root_files_templates
  install_packages
  setup_git
end

# Assert default Rails set up before proceeding with the installation
def assert_default_rails_setup
  assert_postgresql_presence
end

# Check that PostgreSQL is used as application database
def assert_postgresql_presence
  return if IO.read('Gemfile') =~ /^\s*gem ['"]pg['"]/

  raise Rails::Generators::Error, 'This template requires PostgreSQL, but the pg gem isn’t present in your Gemfile.'
end

# Import this template respository to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def download_rails_template
  if __FILE__ =~ %r{\Ahttps?://}
    require 'tmpdir'
    source_paths.unshift(tempdir = Dir.mktmpdir('rails-template-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      '--quiet',
      'https://github.com/vvmarulin/rails-new-template.git',
      tempdir
    ].map(&:shellescape).join(' ')

    if (branch = __FILE__[%r{rails-template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

# Prevent Rails from running installation of bundle and webpack
def skip_packages_installation
  self.options = options.merge(skip_bundle: true)
end

# Run bundle installation
def install_packages
  run_with_clean_bundler_env "bundle install"
end

def run_with_clean_bundler_env(cmd)
  success =
    if defined?(Bundler)
      if Bundler.respond_to?(:with_unbundled_env)
        Bundler.with_unbundled_env { run(cmd) }
      else
        Bundler.with_clean_env { run(cmd) }
      end
    else
      run(cmd)
    end

  raise Rails::Generators::Error, "Command failed, exiting: #{cmd}" unless success
end

def copy_root_files_templates
  template 'LICENSE.tt', force: true
  template 'README.md.tt', force: true
  template 'Gemfile.tt', force: true
end

def gemfile_requirement(name)
  @original_gemfile ||= IO.read('Gemfile')
  req = @original_gemfile[/gem\s+['"]#{name}['"]\s*(,[><~= \t\d\.\w'"]*)?.*$/, 1]
  req && req.gsub("'", %(")).strip.sub(/^,\s*"/, ', "')
end

def setup_git
  git :init
  git checkout: '-b master'
  git add: '-A .'
  git commit: "-n -m 'Set up project'"
end

apply_template!
