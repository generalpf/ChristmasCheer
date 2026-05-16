class AppRevision
  SHORT_LENGTH = 7

  class << self
    def current_sha
      return @current_sha if defined?(@current_sha)

      @current_sha = lookup
    end

    def short_sha
      current_sha&.slice(0, SHORT_LENGTH)
    end

    def reset!
      remove_instance_variable(:@current_sha) if defined?(@current_sha)
    end

    private

    def lookup
      from_env || from_revision_file || from_git || nil
    end

    def from_env
      sanitize(ENV["GIT_COMMIT_SHA"])
    end

    def from_revision_file
      path = Rails.root.join("REVISION")
      return nil unless File.exist?(path)

      sanitize(File.read(path))
    end

    def from_git
      return nil unless Rails.root.join(".git").exist?

      sanitize(`git rev-parse HEAD 2>/dev/null`)
    rescue StandardError
      nil
    end

    def sanitize(value)
      stripped = value.to_s.strip
      stripped.empty? ? nil : stripped
    end
  end
end
