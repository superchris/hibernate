require 'java'

Dir.glob(File.join(File.dirname(__FILE__), "java", "*.jar")).each do |jar|
  require jar
end
require 'stringio'

require 'dialects'

module Hibernate
  import org.hibernate.cfg.AnnotationConfiguration
  import javax.xml.parsers.DocumentBuilderFactory
  import org.xml.sax.InputSource
  JClass = java.lang.Class
  JVoid = java.lang.Void::TYPE
  DOCUMENT_BUILDER_FACTORY = DocumentBuilderFactory.new_instance
  DOCUMENT_BUILDER_FACTORY.validating = false
  DOCUMENT_BUILDER_FACTORY.expand_entity_references = false
  DOCUMENT_BUILDER = DOCUMENT_BUILDER_FACTORY.new_document_builder

  def self.dialect=(dialect)
    config.set_property "hibernate.dialect", dialect
  end

  def self.current_session_context_class=(ctx_cls)
    config.set_property "hibernate.current_session_context_class", ctx_cls
  end

  def self.connection_driver_class=(driver_class)
    config.set_property "hibernate.connection.driver_class", driver_class
  end

  def self.connection_url=(url)
    config.set_property "hibernate.connection.url", url
  end

  def self.connection_username=(username)
    config.set_property "hibernate.connection.username", username
  end

  def self.connection_password=(password)
    config.set_property "hibernate.connection.password", password
  end

  class PropertyShim
    def initialize(config)
      @config = config
    end

    def []=(key, value)
      key = ensure_hibernate_key(key)
      @config.set_property key, value
    end

    def [](key)
      key = ensure_hibernate_key(key)
      config.get_property key
    end

    private
    def ensure_hibernate_key(key)
      unless key =~ /^hibernate\./
        key = 'hibernate.' + key
      end
      key
    end
  end

  def self.properties
    PropertyShim.new(@config)
  end

  def self.tx
    session.begin_transaction
    if block_given?
      yield session
      session.transaction.commit
    end
  end

  def self.factory
    @factory ||= config.build_session_factory
  end

  def self.session
    factory.current_session
  end

  def self.config
    @config ||= AnnotationConfiguration.new
  end

  def self.add_model(model_class)
    config.add_annotated_class(model_class)
  end

  module Model
    TYPES = {
      :string => java.lang.String,
      :long => java.lang.Long,
      :date => java.util.Date
    }

    def hibernate_sigs
      @hibernate_sigs ||= {}
    end

    def add_java_property(name, type, annotation = nil)
      attr_accessor name
      get_name = "get#{name.to_s.capitalize}"
      set_name = "set#{name.to_s.capitalize}"

      alias_method get_name.intern, name
      add_method_signature get_name, [TYPES[type].java_class]
      add_method_annotation get_name, annotation if annotation
      alias_method set_name.intern, :"#{name.to_s}="
      add_method_signature set_name, [JVoid, TYPES[type].java_class]

    end

    def hibernate_attr(attrs)
      attrs.each do |name, type|
        add_java_property(name, type)
      end
    end

    def hibernate_identifier(name, type)
      add_java_property(name, type, javax.persistence.Id => {}, javax.persistence.GeneratedValue => {})

    end
    
    def hibernate!
      add_class_annotation javax.persistence.Entity => {}
      java_class = become_java!

#      Hibernate.mappings.
      Hibernate.add_model java_class
    end
  end
end
