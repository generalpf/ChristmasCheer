require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "commit_link renders short SHA linked to the commit page" do
    with_app_revision(env: "abcdef1234567890abcdef1234567890abcdef12") do
      rendered = commit_link

      assert_includes rendered, ">abcdef1<"
      assert_includes rendered,
        %(href="#{Rails.configuration.x.github_repo_url}/commit/abcdef1234567890abcdef1234567890abcdef12")
    end
  end

  test "commit_link renders 'unknown' span when SHA is unavailable" do
    with_app_revision(env: nil, revision_file: nil, suppress_git: true) do
      rendered = commit_link

      assert_includes rendered, "unknown"
      assert_no_match(/<a /, rendered)
    end
  end

  test "github_repo_link points at the configured repo URL" do
    rendered = github_repo_link

    assert_includes rendered, %(href="#{Rails.configuration.x.github_repo_url}")
    assert_includes rendered, ">GitHub<"
  end
end
