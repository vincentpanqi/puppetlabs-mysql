require 'spec_helper_acceptance'

describe 'mysql class' do

  describe 'running puppet code' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      tmpdir = default.tmpdir('mysql')
      pp = <<-EOS
        class { 'mysql::server':
          config_file             => '#{tmpdir}/my.cnf',
          includedir              => '#{tmpdir}/include',
          manage_config_file      => 'true',
          override_options        => { 'mysqld' => { 'key_buffer_size' => '32M' }},
          package_ensure          => 'present',
          purge_conf_dir          => 'true',
          remove_default_accounts => 'true',
          restart                 => 'true',
          root_group              => 'root',
          root_password           => 'test',
          service_enabled         => 'true',
          service_manage          => 'true',
          users                   => {
            'someuser@localhost' => {
              ensure                   => 'present',
              max_connections_per_hour => '0',
              max_queries_per_hour     => '0',
              max_updates_per_hour     => '0',
              max_user_connections     => '0',
              password_hash            => '*F3A2A51A9B0F2BE2468926B4132313728C250DBF',
            }},
          grants                  => {
            'someuser@localhost/somedb.*' => {
              ensure     => 'present',
              options    => ['GRANT'],
              privileges => ['SELECT', 'INSERT', 'UPDATE', 'DELETE'],
              table      => 'somedb.*',
              user       => 'someuser@localhost',
            },
          },
          databases => {
            'somedb' => {
              ensure  => 'present',
              charset => 'utf8',
            },
          }
        }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end
  end

  describe 'configuration needed for syslog' do
    it 'should work with no errors' do
      pp = <<-EOS
        class { 'mysql::server':
          override_options => { 'mysqld' => { 'log-error' => undef }, 'mysqld_safe' => { 'log-error' => false, 'syslog' => true }},
        }
      EOS

      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end
  end

  describe 'when changing the password' do
    let(:password) { 'THE NEW SECRET' }
    let(:manifest) { "class { 'mysql::server': root_password => '#{password}' }" }

    it 'should not display the password' do
      result = apply_manifest(manifest, :expect_changes => true)
      # this does not actually prove anything, as show_diff in the puppet config defaults to false.
      expect(result.stdout).not_to match /#{password}/
    end

    it 'should be idempotent' do
      result = apply_manifest(manifest, :catch_changes => true)
    end

  end

end
