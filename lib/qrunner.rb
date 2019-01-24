# frozen_string_literal: true

require 'mysql2'
require 'toml-rb'
require 'net/ssh/gateway'

def run_query
  prepare_db_schema if local_exec?
  puts '=' * 30,
       'sending queries',
       query,
       '=' * 30
  @port = gateway.open(host, port, 3307) if gateway? && !local_exec?
  transaction do
    mysql_client.query(query)
    mysql_client.store_result while mysql_client.next_result
  end
rescue SystemExit => e
  puts e
rescue StandardError => e
  raise e
ensure
  mysql_client.close
  gateway.shutdown! if gateway? && !test_query?
end

def prepare_db_schema
  Dir.foreach(schema_dir) { |db|
    next if db == '.' or db == '..'
    mysql_client.query("CREATE DATABASE #{db};")
    `mysql -u#{mysql_username} -h#{host} -P#{port} #{db} < #{schema_dir}/#{db}`
  }
end

def transaction
  mysql_client.query('BEGIN')
  yield
  mysql_client.query('COMMIT')
rescue StandardError => e
  mysql_client.query('ROLLBACK')
  puts 'ROLLBACK TRANSACTION!'
  raise e
end

def query
  unless @query
    File.open(sqlfile, 'r') do |f|
      @query = f.read
    end
  end
  @query
end

def sqlfile
  unless @sqlfile
    fetched = fetch_diff_files.grep(/.sql$/)
    @sqlfile =
      case
        fetched.size
      when 0
        raise SystemExit, 'No SQL file exists!'
      when 1
        fetched.first
      else
        raise "Only one SQL file is available! files:#{fetched.join(',')}"
      end
  end
  @sqlfile
end

def fetch_diff_files
  `git fetch`
  to = 'HEAD'
  from = if ENV['DRONE_BRANCH'] == 'master'
           # When merging to the master, since CI operates in the state after merge, take the difference from the merge commit two times before.
           `git log -n 2 --pretty=oneline --merges #{to} | tail -n 1 | awk '{print $1}'`.chomp
         else
           # When pushing to a branch other than master, take the difference between the branch and master's HEAD.
           'origin/master'
         end
  `git diff #{from}..#{to} --name-only --diff-filter=A | grep -v '^#{schema_dir}/'`.split("\n")
end

def mysql_client
  @mysql_client ||= Mysql2::Client.new(host: host,
                                       port: port,
                                       username: mysql_username,
                                       password: mysql_password,
                                       flags: Mysql2::Client::MULTI_STATEMENTS)
end

def host
  local_exec? ? '127.0.0.1' : server_config[service][host_name].split(':').first
end

def port
  @port ||= if !local_exec? && server_config[service][host_name].include?(':')
              server_config[service][host_name].split(':').last
            else
              3306
            end
end

def mysql_username
  @mysql_username ||= ENV.fetch('MYSQL_USER', 'root')
end

def mysql_password
  @mysql_password ||= ENV.fetch('MYSQL_PASSWORD', '')
end

def server_config
  TomlRB.load_file(servers_info)
end

def servers_info
  @servers_info ||= ENV.fetch('SERVERS_INFO', 'servers.toml')
end

def service
  sqlfile.split('/')[0]
end

def host_name
  sqlfile.split('/')[1]
end

def local_exec?
  exec_mode == 'local'
end

def gateway?
  server_config[service].key?('ssh_gateway')
end

def ssh_host
  server_config[service]['ssh_gateway'].split('@').last
end

def ssh_user
  server_config[service]['ssh_gateway'].split('@').first
end

def gateway
  @gateway ||= Net::SSH::Gateway.new(
    ssh_host,
    ssh_user
  )
end

def schema_dir
  @schema_dir ||= ENV.fetch('SCHEMA_DIR', 'schema')
end

def exec_mode
  @exec_mode ||= ENV.fetch('EXEC_MODE', 'local')
end


run_query if $PROGRAM_NAME == __FILE__
