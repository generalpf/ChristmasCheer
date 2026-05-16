require "test_helper"

class AppRevisionTest < ActiveSupport::TestCase
  test "ENV value wins over REVISION file" do
    with_app_revision(env: "envenvenvenvenvenvenvenvenvenvenvenvenv0",
                      revision_file: "fileefileefileefileefileefileefileefile0\n") do
      assert_equal "envenvenvenvenvenvenvenvenvenvenvenvenv0", AppRevision.current_sha
      assert_equal "envenve", AppRevision.short_sha
    end
  end

  test "REVISION file wins over git fallback when ENV is blank" do
    with_app_revision(env: nil,
                      revision_file: "fileefileefileefileefileefileefileefile0\n") do
      assert_equal "fileefileefileefileefileefileefileefile0", AppRevision.current_sha
    end
  end

  test "returns nil when ENV is blank, no REVISION file, and no git tree" do
    with_app_revision(env: nil, revision_file: nil, suppress_git: true) do
      assert_nil AppRevision.current_sha
      assert_nil AppRevision.short_sha
    end
  end

  test "result is memoized across calls" do
    with_app_revision(env: "memoizememoizememoizememoizememoizemem0") do
      first = AppRevision.current_sha
      ENV["GIT_COMMIT_SHA"] = "changedchangedchangedchangedchangedchan0"

      assert_equal first, AppRevision.current_sha
    end
  end
end
