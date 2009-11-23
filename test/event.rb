# Basic requires
require 'rubygems'
require 'java'
require 'jdbc/hsqldb'
require 'jruby/core_ext'

Hibernate.dialect = Hibernate::Dialects::HSQL
Hibernate.current_session_context_class = "thread"

Hibernate.connection_driver_class = "org.hsqldb.jdbcDriver"
Hibernate.connection_url = "jdbc:hsqldb:memory"
Hibernate.connection_username = "sa"
Hibernate.connection_password = ""
Hibernate.properties["hbm2ddl.auto"] = "update"

class Event
  extend Hibernate::Model
  hibernate_attr :id => :long, :title => :string, :date => :date
  hibernate!

  def initialize(params = {})
    self.title = params[:title]
  end
end

Hibernate.add_model File.join(File.dirname(__FILE__), "Event.hbm.xml")
