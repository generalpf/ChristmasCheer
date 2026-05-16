module ApplicationHelper
  def commit_link
    sha = AppRevision.current_sha
    short = AppRevision.short_sha
    return tag.span("unknown", class: "commit-sha commit-sha--unknown") unless sha && short

    link_to short,
            "#{Rails.configuration.x.github_repo_url}/commit/#{sha}",
            class: "commit-sha",
            target: "_blank",
            rel: "noopener"
  end

  def github_repo_link
    link_to "GitHub",
            Rails.configuration.x.github_repo_url,
            class: "repo-link",
            target: "_blank",
            rel: "noopener"
  end
end
