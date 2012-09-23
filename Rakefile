require 'bundler'

class GemHelperWithForce < Bundler::GemHelper
  def build_gem
    file_name = nil
    sh("gem build -f -V '#{spec_path}'") { |out, code|
      file_name = File.basename(built_gem_path)
      FileUtils.mkdir_p(File.join(base, 'pkg'))
      FileUtils.mv(built_gem_path, 'pkg')
      Bundler.ui.confirm "#{name} #{version} built to pkg/#{file_name}"
    }
    File.join(base, 'pkg', file_name)
  end
end

GemHelperWithForce.install_tasks
