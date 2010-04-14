#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'grit'
require 'haml'
require 'pp'

repo_dir = '/Users/david/gow/repo'
repo = Grit::Repo.new(repo_dir)
top = repo.tree

get '/' do
  top.contents.each.map do |item|
    "<a href=\"/page/%s\">%s</a>" % [ item.name, item.name ]
  end.join("\n")
end

get '/page/:page' do |page|
  blob = top/page
  pp blob.data
  if blob.nil?
    haml :add, :locals => { :data => "", :page => page }
  else
    blob.data
  end
end

get '/page/:page/edit' do |page|
  blob = top/page
  if blob.nil?
    data = ""
  else
    data = blob.data
  end
  haml :add, :locals => { :data => data, :page => page }
end

post '/page/:page' do |page|
  path = File.join(repo_dir, page)
  File.open(path, 'w') { |f|
    s = request.env['rack.input'].read
    puts "got #{s}"
    f.write(s) 
  }
  repo.add(path)
  repo.commit_all("from web: " + request.ip)
  redirect "/page/#{page}"
end

__END__

@@ add
%form{ :method => "post", :action => "/page/#{page}" }
  %textarea{ :rows => 20, :cols => 80 }= data
  %br
  %input{ :type => "submit", :label => "Save Page" }

