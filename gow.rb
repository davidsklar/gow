#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'grit'
require 'haml'
require 'fileutils'

repo_dir = '/Users/david/gow/repo'
repo = Grit::Repo.new(repo_dir)
top = repo.tree

def list_directory(dir) 
  items = []
  dir.contents.each.map do |item|
    if item.class == Grit::Tree
      display_name = item.name + "/"
    else
      display_name = item.name
    end
    items << "<a href=\"/page/%s\">%s</a> <br/>" % [ item.name, display_name ]
  end
  items
end

get '/' do
  items = list_directory(top)
  haml :list, :locals => { :items => items }
end

get '/page/*' do 
  page = params['splat'][0]
  child = top / page
  if child.class == Grit::Tree
    items = list_directory(child)
    haml :list, :locals => { :items => items }
  elsif child.nil?
    haml :add, :locals => { :data => "", :page => page }
  else
    child.data
  end
end

get '/edit/*' do
  page = params['splat'][0]
  child = top / page
  if child.nil?
    data = ""
  elsif child.class == Grit::Tree
    raise "blearght! can't edit existing directory!"
  else
    data = child.data
  end
  haml :add, :locals => { :data => data, :page => page }
end

post '/edit/*' do
  page = params['splat'][0]
  path = File.join(repo_dir, page)
  dir = File.dirname(path)
  FileUtils.mkdir_p(dir) # some error checking would be nice
  File.open(path, 'w') { |f| f.write(params['contents']) } # some error checking would be nice here, too
  repo.add(path)
  repo.commit_index("#{page} from web: " + request.ip)
  redirect "/page/#{params['splat']}"
end

__END__

@@ add
%form{ :method => "post", :action => "/edit/#{page}" }
  %textarea{:name => "contents", :rows => 20, :cols => 80 }= data
  %br
  %input{ :type => "submit", :label => "Save Page" }

@@ list
%ul
  - items.each do |item|
    %li= item
