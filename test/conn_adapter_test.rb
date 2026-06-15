# frozen_string_literal: true

require_relative 'helper'

class ConnAdapterTest < QCTest
  class FakeConnection
    attr_reader :statements, :wait_time

    def initialize
      @statements = []
      @wait_time = nil
    end

    def exec(statement)
      @statements << statement
      []
    end

    def wait_for_notify(time)
      @wait_time = time
    end

    def notifies
      nil
    end
  end

  def setup
    QC.reset_config
  end

  def teardown
    QC.reset_config
  end

  # This test ensures that the connection adapter 
  # correctly uses LISTEN/NOTIFY when waiting for 
  # jobs, and falls back to sleeping when 
  # LISTEN/NOTIFY is disabled.
  def test_wait_uses_listen_notify_by_default
    connection = FakeConnection.new
    adapter = QC::ConnAdapter.new(connection: connection)

    adapter.wait(0, 'default')

    assert_includes connection.statements, 'LISTEN "default"'
    assert_includes connection.statements, 'UNLISTEN "default"'
    assert_equal 0, connection.wait_time
  end

  # This test ensures that the connection 
  # adapter falls back to polling when 
  # LISTEN/NOTIFY is disabled.
  def test_wait_uses_polling_sleep_when_listen_notify_is_disabled
    connection = FakeConnection.new
    adapter = QC::ConnAdapter.new(connection: connection)

    with_env 'QC_LISTEN_NOTIFY' => 'false' do
      QC.reset_config
      adapter.wait(0, 'default')
    end

    assert_empty connection.statements
    assert_nil connection.wait_time
  end
end



