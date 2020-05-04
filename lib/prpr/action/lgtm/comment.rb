module Prpr
  module Action
    module Lgtm
      class Comment < Prpr::Action::Base
        def call
          if count == 1
            add_label label(:one)
          elsif count >= 2
            unless already_labeled?(label(:over_2))
              remove_label label(:one)
              add_label label(:over_2)
              add_comment
            end
          end
        end

        private

        def count
          last_state.map(&method(:point)).reduce(0, :+)
        end

        def last_state
          last_state = {}
          reviews.each do|review|
            if review[:state] != 'COMMENTED'
              last_state[review[:user][:login]] = review[:state]
            end
          end
          last_state.values
        end

        def point(state)
          case state
          when 'APPROVED'
            1
          when 'CHANGES_REQUESTED'
            -1
          else
            0
          end
        end

        def reviews
          # FIXME: use offical method
          @reviews ||=
            github.get "#{Octokit::Repository.path repository}/pulls/#{pull_request_number}/reviews?per_page=100",
              accept: 'application/vnd.github.black-cat-preview+json'
        end

        def add_comment
          github.add_comment(repository, pull_request_number, message)
        end

        def message
          env.format(:lgtm_body, event.pull_request.assignee)
        end

        def add_label(label)
          return if already_labeled?(label)
          github.add_labels_to_an_issue(repository, pull_request_number, [label])
        end

        def remove_label(label)
          return unless already_labeled?(label)
          github.remove_label(repository, pull_request_number, label)
        end

        def already_labeled?(label)
          labels.map(&:name).any? { |name| name == label }
        end

        def labels
          event.pull_request.labels
        end

        def label(name)
          Config::Env.default[:"lgtm_label_#{name}"] || name.to_s
        end

        def name
          env[:mention_comment_members] || 'MEMBERS.md'
        end

        def repository
          event.repository.full_name
        end

        def pull_request_number
          event.pull_request.number
        end

        def github
          Repository::Github.default
        end
      end
    end
  end
end
