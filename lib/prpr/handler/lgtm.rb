module Prpr
  module Handler
    class Lgtm < Base
      handle Event::IssueComment do
        Prpr::Action::Lgtm::Comment.new(event).call
      end
    end
  end
end
