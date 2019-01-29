# qrunner
Query runner for executing queries merged after review at the PR in CI.  
Currently qrunner is supposed to work in conjunction with Drone CI and MySQL.  
An example of Drone's configuration file is [here](.drone.yml).  

## Configuration
### Environment variables (can overwrite by `.drone.yml`)

| variables | example values | description |
| --------- | ------ | ----------- |
| `EXEC_MODE` | `local` or `remote` | In case of `local`, run query for the localhost MySQL for testing |
| `SCHEMA_DIR` | `schema` | Under `SCHEMA_DIR` is used for testing (when `EXEC_MODE = 'local'`).  The file name is assumed to be the same as the DB name |
| `SERVERS_INFO` | `servers.toml` | Server connection information (it must be a toml format file) |
| `MYSQL_USER`| `root` | Username of MySQL |
| `MYSQL_PASSWORD`| `"your_mysql_password"` | Password of MySQL |

### Server Information File
Sample is [Here](servers.toml).  
```
[service_name]
mydb = "<Hostname or IP address>[:port]"
```
You can specify the port on which MySQL is running after the  `:`. (If not specified the default is 3306)  
`mydb` is a key name that uniquely indicates the DB server and is used as the directory name of the place of the query.  (Describe later)  

