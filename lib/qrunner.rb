# frozen_string_literal: true

require 'mysql2'
require 'toml-rb'
require 'net/ssh/gateway'

def run_query
  puts '=' * 30,
       'sending queries',
       query,
       '=' * 30
  @port = gateway.open(host, port, 3307) if gateway? && !test_query?
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
           # masterマージの際、droneではマージコミット後の状態が見えているため、その前のマージコミットとHEADの差分を取る
           `git log -n 2 --pretty=oneline --merges #{to} | tail -n 1 | awk '{print $1}'`.chomp
         else
           # master以外のブランチにpushした際は、ブランチのHEADとmasterのHEADの差分を取る
           'origin/master'
         end
  `git diff #{from}..#{to} --name-only --diff-filter=A | grep -v '^db/'`.split("\n")
end

def mysql_client
  @mysql_client ||= Mysql2::Client.new(host: ENV['MYSQL_HOST'] || host,
                                       port: ENV['MYSQL_PORT'] || port,
                                       username: ENV['MYSQL_USER'] || 'root',
                                       password: ENV['MYSQL_PASSWORD'] || '',
                                       flags: Mysql2::Client::MULTI_STATEMENTS)
end

def host
  server_config[service][host_name].split(':').first
end

def port
  @port ||= if server_config[service][host_name].include?(':')
              server_config[service][host_name].split(':').last
            else
              3306
            end
end

def server_config
  TomlRB.load_file('servers.toml')
end

def service
  sqlfile.split('/')[0]
end

def host_name
  sqlfile.split('/')[1]
end

def test_query?
  ENV['MYSQL_HOST'] == '127.0.0.1'
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

run_query if $PROGRAM_NAME == __FILE__
