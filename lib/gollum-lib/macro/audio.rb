module Gollum
  class Macro
    class Audio < Gollum::Macro
      def render (fname)
        fname = @wiki.base_path + '/' + fname unless @wiki.base_path.empty?
        "<audio width=\"100%\" height=\"100%\" src=\"#{fname}\" controls=\"\"> HTML5 audio is not supported on this Browser.</audio>"
      end
    end
  end
end
