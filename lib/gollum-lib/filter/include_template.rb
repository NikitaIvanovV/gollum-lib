# ~*~ encoding: utf-8 ~*~
class Gollum::Filter::IncludeTemplate < Gollum::Filter
  EXTRACT_PATTERN = %r{
    (?<!\\|\{)   # make template syntax escapable with backslash
    \{\{(?!\{)
      ([^{}]+?)  # template body
    \}\}
  }xm

  NAME_CHARS_SET = /[\w-]/

  SYNTAX_PATTERN = {
    body: %r/(?<name>#{NAME_CHARS_SET}+?(?=$|\||\n))(?<args>.*)/m,
    arg: /\|\s*(#{NAME_CHARS_SET}+)\s*(?:=([^|]*))?/m
  }

  def extract(data)
    loop do
      break unless data.match?(EXTRACT_PATTERN)

      data.gsub! EXTRACT_PATTERN do
        begin
          spec = parse_template($~[1])
        rescue => e
          next html_error(e)
        end
        register_tag(spec)
      end
    end

    data
  end

  def process(data)
    @map.each do |id, spec|
      spec[:args].each do |arg, value|
        next unless value.match /#{open_pattern}[a-z0-9]{40}#{close_pattern}/
        @map[id][:args][arg] = process_templates(value)
      end
    end

    process_templates(data)
  end

  private

  def register_tag(tag)
    id       = "#{open_pattern}#{Digest::SHA1.hexdigest(tag.to_s)}#{close_pattern}"
    @map[id] = tag
    id
  end

  def process_templates(string)
    s = string.dup
    @map.each do |id, spec|
      s.gsub!(id) { render_template(spec[:name], spec[:args]) }
    end
    s
  end

  def parse_template(string)
    body_match = SYNTAX_PATTERN[:body].match(string)

    temp = {}
    temp[:name] = body_match[:name]

    positional_arg = 1
    temp[:args] = {}
    body_match[:args].scan(SYNTAX_PATTERN[:arg]) do |v1, v2|
      unless v2.nil?
        arg = v1
        if /^[0-9]+$/.match? arg
          arg = arg.to_i
        end
        value = v2
      else
        arg = positional_arg
        positional_arg += 1
        value = v1
      end

      temp[:args][arg] = value.strip
    end

    temp
  end

  def render_template(name, args)
    page = find_page_or_file_from_path(name)
    return html_error("Template #{name} not found") if page.nil?
    page.formatted_data(nil, nil, args)
  end

  def find_page_or_file_from_path(path, kind = :page)
    if Pathname.new(path).relative?
      result = @markup.wiki.send(kind, ::File.join(@markup.dir, path))
      if result.nil? && @markup.wiki.global_tag_lookup # 4.x link compatibility option. Slow!
        result = @markup.wiki.send(kind, path, nil, true)
      end
      result
    else
      @markup.wiki.send(kind, path)
    end
  end
  
end
