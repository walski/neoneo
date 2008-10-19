# -*- ruby -*-

require 'rubygems'
require 'hoe'
require 'mechanize'
require './lib/neoneo.rb'

Hoe.new('neoneo', Neoneo::VERSION) do |p|
  p.rubyforge_name = "kickassrb"
  p.name = "neoneo"
  p.author = "Thorben Schröder"
  p.description = "Ruby wrapper to access No Kahuna (www.nokahuna.com) from within your Ruby projects."
  p.email = 'thorben@fetmab.net'
  p.summary = "Ruby wrapper to access No Kahuna (www.nokahuna.com) from within your Ruby projects."
  p.changes = p.paragraphs_of('History.txt', 0..1).join("\n\n")
  p.extra_deps << ['mechanize'," >=0.8.4"]
end

# vim: syntax=Ruby
