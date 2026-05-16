module AppRevisionTestHelper
  def with_app_revision(env: :unset, revision_file: :unset, suppress_git: false)
    original_env_value = ENV["GIT_COMMIT_SHA"]
    original_env_present = ENV.key?("GIT_COMMIT_SHA")
    revision_path = Rails.root.join("REVISION")
    revision_path_existed = File.exist?(revision_path)
    revision_backup = File.read(revision_path) if revision_path_existed

    case env
    when :unset then ENV.delete("GIT_COMMIT_SHA")
    when nil    then ENV["GIT_COMMIT_SHA"] = ""
    else             ENV["GIT_COMMIT_SHA"] = env
    end

    case revision_file
    when :unset then File.delete(revision_path) if revision_path_existed
    when nil    then File.delete(revision_path) if revision_path_existed
    else             File.write(revision_path, revision_file)
    end

    if suppress_git
      AppRevision.singleton_class.send(:alias_method, :__from_git_original, :from_git)
      AppRevision.define_singleton_method(:from_git) { nil }
    end

    AppRevision.reset!
    yield
  ensure
    if suppress_git && AppRevision.singleton_class.private_method_defined?(:__from_git_original)
      AppRevision.singleton_class.send(:alias_method, :from_git, :__from_git_original)
      AppRevision.singleton_class.send(:remove_method, :__from_git_original)
    end

    File.delete(revision_path) if File.exist?(revision_path)
    File.write(revision_path, revision_backup) if revision_path_existed

    if original_env_present
      ENV["GIT_COMMIT_SHA"] = original_env_value
    else
      ENV.delete("GIT_COMMIT_SHA")
    end

    AppRevision.reset!
  end
end

ActiveSupport.on_load(:active_support_test_case) do
  include AppRevisionTestHelper
end

ActiveSupport.on_load(:action_view_test_case) do
  include AppRevisionTestHelper
end
