require 'helper'
require 'event'

class TestHibernate < Test::Unit::TestCase
  def test_save
    event = Event.new
    event.title = "Foo"
    event.id = 99
    Hibernate.tx do |session|
      session.save(event)
    end
  end
end
