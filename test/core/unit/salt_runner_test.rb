require 'test_helper'
require 'dynflow'
require 'foreman_remote_execution_core'
require 'smart_proxy_salt_core'

module SmartProxySaltCore
  class SaltRunnerTest < Test::Unit::TestCase
    def test_capture_jid
      data = <<-EOF
        [WARNING ] /usr/lib/python3.7/site-packages/salt/transport/ipc.py:292: DeprecationWarning: encoding is deprecated, Use raw=False instead.
          self.unpacker = msgpack.Unpacker(encoding=encoding)

        jid: 20190709172718917803
        [WARNING ] /usr/lib/python3.7/site-packages/salt/payload.py:149: DeprecationWarning: encoding is deprecated, Use raw=False instead.
          ret = msgpack.loads(msg, use_list=True, ext_hook=ext_type_decoder, encoding=encoding)

        258b7c8b6c9d:
            True
      EOF
      runner = SaltRunner.new({}, suspended_action: nil)
      assert_nil runner.jid
      runner.publish_data(data, 'stdout')
      assert_equal '20190709172718917803', runner.jid
      # Once set, the jid does not change
      runner.publish_data('my custom jid: 12345', 'stdout')
      assert_equal '20190709172718917803', runner.jid
    end

    def test_override_exit_status
      runner = SaltRunner.new({}, suspended_action: nil)
      assert_nil runner.jid
      assert_equal 1, runner.publish_exit_status(0)
      runner.publish_data('jid: 12345', 'stdout')
      assert_equal 0, runner.publish_exit_status(0)
    end

    def test_generate_command
      runner = SaltRunner.new({ 'name' => 'a-host', 'script' => 'ls -la /' },
                              suspended_action: nil)
      File.expects(:file?).returns(false)
      expected = %w(salt --show-jid a-host state.template_str) << 'ls -la /'
      assert_equal expected, runner.send(:generate_command)
    end
  end
end
