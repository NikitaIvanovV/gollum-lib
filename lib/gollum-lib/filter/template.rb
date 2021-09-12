# ~*~ encoding: utf-8 ~*~
class Gollum::Filter::Template < Gollum::Filter
  EXTRACT_PATTERN = %r{
    (?<!\\)                         # make template syntax escapable with backslash
    \{\{\{
      \s*(?<arg>[\w-]+)\s*          # arg name
      (?:\|\s*(?<default>.*?)\s*)?  # default value
    \}\}\}
  }xm

  def extract(data)
    data.gsub(EXTRACT_PATTERN) do
      tag = $~.named_captures.transform_keys(&:to_sym)
      tag[:arg] = tag[:arg].to_i if tag[:arg].match? /^\d+$/
      register_tag(tag)
    end
  end

  def process(data)
    @map.each do |id, spec|
      data.gsub! id do
        next CGI.escapeHTML("{{{#{spec[:arg]}}}}") if @markup.template_args.nil?
        value = @markup.template_args[spec[:arg]]
        unless value.nil?
          value
        else
          spec[:default]
        end
      end
    end

    data
  end

  private

  def register_tag(tag)
    id       = "#{open_pattern}#{Digest::SHA1.hexdigest(tag.to_s)}#{close_pattern}"
    @map[id] = tag
    id
  end
  
end
