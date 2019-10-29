#!/usr/bin/env ruby

require 'pp'

@md = []

def directory_hash(path, name=nil)
  data = {:data => (name || path)}
  data[:children] = children = []
  Dir.foreach(path) do |entry|
    # next if (entry == '..' || entry == '.')
    next if entry =~ /^\./
    full_path = File.join(path, entry)
    if File.directory?(full_path)
      children << directory_hash(full_path, entry)
    end
  end
  return data
end


def built_list(dir, parent=nil, level=0)
  name = dir[:data]
  path = parent.nil? ? name : File.join(parent, name)

  @md << "  " * level + "* [#{name}](#{path})"

  children = dir[:children]
  if children.length > 0
    children.sort_by{|c| c[:data]}.each do |c|
      built_list(c, path, level+1)
    end
  end
end

# pp directory_hash("playbooks")

built_list(directory_hash("playbooks"))
# pp @md

content = "# All Playbooks\n\n" + @md.join("\n")
File.write("playbooks.md", content)
