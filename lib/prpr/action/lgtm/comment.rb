module Prpr
  module Action
    module Lgtm
      class Comment < Prpr::Action::Base
        def call
          if count == 1
            add_label label(:one)
          elsif count >= 2
            unless already_labeled?(label(:over_2))
              add_comment
              remove_label label(:one)
              add_label label(:over_2)
            end
          end
        end

        private

        def count
          comments.map(&method(:point)).reduce(:+)
        end

        def point(comment)
          case comment[:body]
          when /lgtm/i, /:+1:/
            1
          when /:-1:/
            -1
          else
            0
          end
        end

        def comments
          @comments ||= github.issue_comments(repository, issue_number)
        end

        def add_comment
          github.add_comment(repository, issue_number, message)
        end

        def message
          env.format(:lgtm_body, event.issue.assignee)
        end

        def add_label(label)
          github.add_labels_to_an_issue(repository, issue_number, [label])
        end

        def remove_label(label)
          github.remove_label(repository, issue_number, label)
        end

        def already_labeled?(label)
          labels.map(&:name).any? { |name| name == label }
        end

        def labels
          github.labels_for_issue(repository, issue_number)
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

        def issue_number
          event.issue.number
        end

        def github
          Repository::Github.default
        end
      end
    end
  end
end
