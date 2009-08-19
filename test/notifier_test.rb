require File.dirname(__FILE__) + '/helper'

class NotifierTest < Test::Unit::TestCase

  include DefinesConstants

  def setup
    super
    reset_config
  end

  def assert_sent(notice, notice_args)
    assert_received(HoptoadNotifier::Notice, :new) {|expect| expect.with(has_entries(notice_args)) }
    assert_received(notice, :to_xml)
    assert_received(HoptoadNotifier.sender, :send_to_hoptoad) {|expect| expect.with(notice.to_xml) }
  end

  def set_public_env
    define_constant('RAILS_ENV', 'production')
  end

  def set_development_env
    define_constant('RAILS_ENV', 'development')
  end

  # TODO: what does this test?
  should "send without rails environment" do
    assert_nothing_raised do
      HoptoadNotifier.environment_info
    end
  end

  should "send information about the notifier in the headers" do
    assert_equal "Hoptoad Notifier", HoptoadNotifier::HEADERS['X-Hoptoad-Client-Name']
    assert_equal HoptoadNotifier::VERSION, HoptoadNotifier::HEADERS['X-Hoptoad-Client-Version']
  end

  should "yield and save a configuration when configuring" do
    yielded_configuration = nil
    HoptoadNotifier.configure do |config|
      yielded_configuration = config
    end

    assert_kind_of HoptoadNotifier::Configuration, yielded_configuration
    assert_equal yielded_configuration, HoptoadNotifier.configuration
  end

  should_eventually "use standard rails logging filters on params and env" do
    ::HoptoadController.class_eval do
      filter_parameter_logging :ghi
    end
    controller = HoptoadController.new

    expected = {"notice" => {"request" => {"params" => {"abc" => "123", "def" => "456", "ghi" => "[FILTERED]"}},
                           "environment" => {"abc" => "123", "ghi" => "[FILTERED]"}}}
    notice   = {"notice" => {"request" => {"params" => {"abc" => "123", "def" => "456", "ghi" => "789"}},
                           "environment" => {"abc" => "123", "ghi" => "789"}}}
    assert controller.respond_to?(:filter_parameters)
    assert_equal( expected[:notice], controller.send(:clean_notice, notice)[:notice] )
  end

  should "configure the sender" do
    sender = stub_sender
    HoptoadNotifier::Sender.stubs(:new => sender)
    configuration = nil

    HoptoadNotifier.configure { |yielded_config| configuration = yielded_config }

    assert_received(HoptoadNotifier::Sender, :new) { |expect| expect.with(configuration) }
    assert_equal sender, HoptoadNotifier.sender
  end

  should "create and send a notice for an exception" do
    set_public_env
    exception = build_exception
    stub_sender!
    notice = stub_notice!

    HoptoadNotifier.notify(exception)

    assert_sent notice, :exception => exception
  end

  should "create and send a notice for a hash" do
    set_public_env
    notice = stub_notice!
    notice_args = { :error_message => 'uh oh' }
    stub_sender!

    HoptoadNotifier.notify(notice_args)

    assert_sent(notice, notice_args)
  end

  should "create and sent a notice for an exception and hash" do
    set_public_env
    exception = build_exception
    notice = stub_notice!
    notice_args = { :error_message => 'uh oh' }
    stub_sender!

    HoptoadNotifier.notify(exception, notice_args)

    assert_sent(notice, notice_args.merge(:exception => exception))
  end

  should "not create a notice in a development environment" do
    set_development_env
    sender = stub_sender!

    HoptoadNotifier.notify(build_exception)
    HoptoadNotifier.notify_or_ignore(build_exception)

    assert_received(sender, :send_to_hoptoad) {|expect| expect.never }
  end

  should "not deliver an ignored exception when notifying implicitly" do
    set_public_env
    exception = build_exception
    sender = stub_sender!
    notice = stub_notice!
    notice.stubs(:ignore? => true)

    HoptoadNotifier.notify_or_ignore(exception)

    assert_received(sender, :send_to_hoptoad) {|expect| expect.never }
  end

  should "deliver an ignored exception when notifying manually" do
    set_public_env
    exception = build_exception
    sender = stub_sender!
    notice = stub_notice!
    notice.stubs(:ignore? => true)

    HoptoadNotifier.notify(exception)

    assert_sent(notice, :exception => exception)
  end

  should "pass config to created notices" do
    exception = build_exception
    config_opts = { 'one' => 'two', 'three' => 'four' }
    notice = stub_notice!
    stub_sender!
    HoptoadNotifier.configuration = stub('config', :merge => config_opts, :public? => true)

    HoptoadNotifier.notify(exception)

    assert_received(HoptoadNotifier::Notice, :new) do |expect|
      expect.with(has_entries(config_opts))
    end
  end

end
