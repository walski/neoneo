$LOAD_PATH << File.dirname(__FILE__)

module Neoneo
  require 'rubygems'
  require 'mechanize'
  
  require 'hpricot_extensions'
  require 'utils'
  require 'conf'
  
  
  BASE_URL    = 'http://nokahuna.com/'
  PROJECT_URL = "#{BASE_URL}projects/"  
  VERSION     = '0.1.0'
  
  # A Neoneo::AuthenticationError is thrown whenever No Kahuna reports, that 
  # you're not logged in properly.
  class AuthenticationError < StandardError; end
  
  # The default/fallback Error in NeoNeo
  #
  # Neoneo::Error is the default error that is thown any time No Kahuna reports
  # and error which Neoneo is not able to handle properly. Maybe because there
  # is no error handler for that kind of error implemented or because No Kahuna
  # changed it's interface and Neoneo has not yet been updated to reflect those
  # changes
  class Error < ArgumentError; end
  
  # Normal array with a few select extensions
  class SingleSelectArray < Array

    # Find an item in the array by it's name
    def find(name)
      self.select {|item| item.name == name}.first
    end
    
    # Find an item in the array by it's name when value is a string.
    # If the passed value is a Member or Category object just return that and
    # if none of those rules apply return nil.
    #
    # This method allows the user e.g. to assign new task by just using the
    # name of the project member and not it's corresponding Member object. 
    def find_or_use(value)
      case value
      when String
        result = find(value)
      when Member, Category, Project
        result = value
      else
        result = nil
      end
      result
    end
  end
  
  # Wrapper around the WWW::Mechanize object to allow an easy and DRY error
  # handling.
  #
  # Ath the moment only the get, post and submit methods are subject of this
  # error handling.
  class Agent < WWW::Mechanize
    def get(url)
      page = super(url)
      handle_errors(page)
    end
    
    def post(url)
      page = super(url)
      handle_errors(page)
    end
    
    def submit(form)
      page = super(form)
      handle_errors(page)
    end
      
    # This methos actually does the error handling.
    #
    # When an error message is found in the response from No Kahuna it's
    # text determines which error is thrown.
    # If the error message does not match any of the specific messages Neoneo
    # tries to catch, a default Neoneo::Error is thrown.
    def handle_errors(page)
      errors = page.search('div#flash.error p').map {|e| e.innerText}
      errors.each do |error|
        case error
        when 'Invalid login or password.'
          raise AuthenticationError
        else
          raise Error.new(e)  
        end
      end
      
      page
    end
  end
  
  # The starting point for any use of the NeoNeo library.
  #
  # Other than a Neoneo::Member iy represents a user of No Kahuna of wich you
  # have the full login credentials.
  #
  # To initialize a connection to No Kahuna start with:
  #
  #   Neoneo::User.new('User Name', 'Password')
  #
  # Neoneo then loggs you in to No Kahuna and gathers some first informations
  # about your projects, task counts and so on.
  # 
  # Unfortunately  the initialization process needs to do actually three HTTP
  # requests at the moment. First it sets your language to English, than it
  # has to get the login form to be aware of the CSRF id to actually log you
  # in in a third request, the submission of the login form.
  #
  # Also there is no way to check the stay logged in option of No Kahuna yet.
  # This is planned for a future version. 
  class User
    attr_reader :projects
  
    def initialize(user, pass)
      @agent = Agent.new
      
      @agent.post("#{BASE_URL}settings/use_locale?locale=en-US")
      
      page = @agent.get("#{BASE_URL}login")

      form = page.forms.first
      form.login = user
      form.password = pass

      page = @agent.submit(form)
        
      @projects = SingleSelectArray.new  
        
      page.search('ul.projectList li a').each do |project_link|
        name       = project_link.children.last.clean
        total_taks = project_link.search('span.taskCount span.total').first.clean
        own_tasks  = project_link.search('span.taskCount').first.children.first.clean.gsub(/^(\d+)\s\//, '\1').to_i
        id         = project_link.attributes['href'].gsub(/^#{PROJECT_URL}(\d+)\/.*$/, '\1')

        @projects << Project.new(id, name, total_taks, own_tasks, @agent)
      end
    
    end
  
  end
  
  # Representation of No Kahuna's projects.
  #
  # It holds all information about a project, like it's name and description,
  # it's categories, members and tasks. It's also used to add new tasks to
  # a project and can also be used to change the name and description of the
  # project.
  class Project
    attr_reader   :id, :agent
    attr_accessor :name, :total_tasks, :own_tasks, :description
    
    def initialize(id, name, total_tasks, own_tasks, agent)
      @id                = id
      @name              = name
      @total_tasks_count = total_tasks
      @own_tasks_count   = own_tasks
      
      @agent             = agent
    end
    
    def description
      unless @description
        page = @agent.get(url)
        @description = page.search('div.projectDescription p').last.clean
      end
      @description
    end
    
    def description=(new_description)
      @description = new_description
    end
    
    def categories
      build_categories!(@agent.get(url('tasks/new'))) unless @categories
      
      @categories
    end
    
    def members
      build_members!(@agent.get(url('tasks/new'))) unless @members
      
      @members
    end
    
    def tasks
      build_tasks!(@agent.get(url('tasks?group_by=category'))) unless @tasks
      
      @tasks
    end
    
    # Adds a task to a project.
    # The options hash can consist of the following keys:
    #  - :category  => 'Some Category Name' OR some_category_object
    #  - :assign_to => 'Some User Name' OR some_member_object
    #  - :notify    => 'Some User Name' OR some_member_object OR an array of them
    # An example:
    # project = Neoneo::User.new('John Doe', 'god').projects.find('My Project')
    # project.add_task("A shiny new task", 
    #                  :assign_to => 'Bob Dillan', 
    #                  :category => project.categories.first,
    #                  :notify   => ['John Doe', project.members.last])
    def add_task(description, options = {})
      page = @agent.get(url('tasks/new'))
      
      build_categories!(page) unless @categories
      build_members!(page)    unless @members
      
      category  = categories.find_or_use(options[:category])
      assign_to = members.find_or_use(options[:assign_to])
      
      notifications = Array.new
      case options[:notify]
      when Array
        options[:notify].each do |member|
          notifications << members.find_or_use(member)
        end
      else
        notifications << members.find_or_use(options[:notify])
      end
      notifications.compact!
      
      page = @agent.get(url('tasks/new'))
      form = page.forms.last
      
      form.send('task[body]'.to_sym, description)
      form.send('task[assigned_to_id]'.to_sym, assign_to.id) if assign_to
      form.send('task[category_id]'.to_sym,    category.id) if category
      
      notifications.each do |notification|
        form.add_field!('subscriber_ids[]', notification.id)
      end
      
      @agent.submit form
    end
    
    # Saves the project name and descriptions which you can set simply with
    # name= and description=
    # An example:
    # project = Neoneo::User.new('John Doe', 'god').projects.find('My Project')
    # project.name = 'BLA!'
    # project.description = 'New description'
    # project.save
    def save
      page = @agent.get(url('edit'))
      form = page.forms.last
      form.send('project[name]='.to_sym, @name)
      form.send('project[description]='.to_sym, @description) if @description
      page = @agent.submit form

      raise Error unless page.search('div#flash.notice p').first.clean == 
                        'Successfully saved project'
    end
    
    # The URL to the project at No Kahuna
    def url(appendix = '')
      "#{PROJECT_URL}#{@id}/#{appendix}"
    end
    
    private
    
    def build_members!(page)
      @members = SingleSelectArray.new
      
      members = page.search('select#task_assigned_to_id option')
      members.each do |member| 
        id = member.attributes['value']
        @members << Member.new(id, member.innerText, self) unless id.empty?
      end
    end
    
    def build_categories!(page)
      @categories = SingleSelectArray.new
      
      categories = page.search('select#task_category_id option')
      categories.each do |category| 
        id = category.attributes['value']
        @categories << Category.new(id, category.innerText, self) unless id.empty?
      end
    end
    
    
    def build_tasks!(page)
      @tasks = SingleSelectArray.new
      
      categories = page.search('div#task_list_grouped_by_category div.taskList')
      
      categories.each do |category_div|
        category   = self.categories.find(category_div.search('h2').first.clean)
        tasks      = category_div.search('ul.sortable_tasks li')
        tasks.each do |task_item|
          user = Utils::URL.url_unescape(task_item.search('span.avatar a').first.attributes['href'].gsub(/^\/users\//, ''))
          task_link = task_item.search('a.taskLink')
          id          = task_link.search('span.taskId').first.clean
          description = task_link.search('span.taskShortBody').first.clean
          @tasks << Task.new(id, description, category, members.find(user), self)
        end
      end
    end
  end
  
  class Category
    attr_reader :id
    attr_accessor :name
    
    def initialize(id, name, project)
      @id      = id
      @name    = name
      @project = project
    end
    
    def add_task(description, options = {})
      options[:category => self]
      @project.add_task(description, options)
    end
  end
  
  class Member
    attr_reader   :id
    attr_accessor :name
    
    def initialize(id, name, project)
      @id      = id
      @name    = name
      @project = project
    end
  end
  
  class Task
    attr_reader   :id, :user, :project, :category
    
    def initialize(id, description, category, user, project)
      @id = id
      @description = description
      @category = category
      @user = user
      @project = project
      
      @uncertain = @description =~ /\.{3}$/
    end
    
    def description
      build_description! if @uncertain
      @description
    end
    
    def url(appendix = '')
      @project.url("tasks/#{@id}/#{appendix}")
    end
    
    private
    def build_description!
      page = project.agent.get(url('edit'))
      form = page.forms.last
      @description = form.send('task[body]'.to_sym)
      @uncertain = false
    end
  end
  
end

# user = Neoneo::User.new('NeoNeo_Test', Pass.pass)
# project = user.projects.find('NeoNeo')
# p project.tasks.map {|t| a = []; a << (t.user ? t.user.name : ''); a << (t.category ? t.category.name : ''); a}
# # 
# # 20.times do 
# #   project.add_task("NEONEO Test #{Time.now}", :assign_to => project.members[rand(project.members.size)], :category => 'Trash')
# # end