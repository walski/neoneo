= NeoNeo

== DESCRIPTION:

NeoNeo is a Ruby wrapper to access No Kahuna (www.nokahuna.com) from within your Ruby projects.

It uses mechanize and tends to be a bit slow but hey, it's the only ready to use
library today so enjoy it, improve it or go away ;)

== SYNOPSIS:

  require 'rubygems'
  require 'neoneo'

  project = Neoneo::User.new('user name', 'password').projects.find('My Project')
  project.name = "Cool project"
  project.save
  
  p project.tasks.map {|t| t.name}
  
  project.categories.find('An existing Category').add_task("Cool new Task",
                                                           :assign_to => 'Some Username')

  project.add_task("Another way to add a task and notify ANYONE ;)", 
                   :notify => project.members, :category => "Some Category")

== REQUIREMENTS:

* Mechanize (http://mechanize.rubyforge.org/mechanize/)

== INSTALL:

* sudo gem install neoneo

== PERFORMANCE:

As No Kahuna does not provide a real API to their services Neoneo wraps the 
normal HTML pages as you can see them in your browser. This means not thaaaat
speedy performance. Especially because the No Kahuna guys using Rails cool 
CSRF avoiding technology and deliver any form with a token which you have to
sent back to the server to confirm that you're not working on a stolen session.
Due to this e.g. the login procedure consists of THREE HTTP request :/
1. Set the language of the interface to english to allow Neoneo to parse any 
   messages correctly
2. Get the login form (with that token)
3. Post that login form

But I've tried hard to suck as much information as possible out of any HTML
page Neoneo is receiving and to lazy-load most of the details.
E.g. when you log in Neoneo can scan all your projects etc from the initial page
you get after a login. So no second (or forth to be correct ;) ) request is
needed to get a project list. And if you would like to get all the members of
a specific project Neoneo checks if they are already present, if not the
projects detail page is loaded and all the members are gatherd (along with any
other useful information from that page). If you call the members method again,
no new request is needed.

Just want to let you know all this. Neoneo is usable but it's more like a
No Kahuna Information Delivery Bus than a No Kahuna Dragster!

== LICENSE:

(The MIT License)

Copyright (c) 2008 FIX

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
