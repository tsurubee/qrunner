# qrunner
Query runner for executing queries merged after review at the PR in CI.  
Currently qrunner is supposed to work in conjunction with Drone CI and MySQL.  
An example of Drone's configuration file is [here](.drone.yml).  

## Configuration

※ Japanese version [here](docs/README_japanese_ver.md).  

### Environment variables (can overwrite by `.drone.yml`)

| variables | example values | description |
| --------- | ------ | ----------- |
| `EXEC_MODE` | `local` or `remote` | In case of `local`, run query for the localhost MySQL for testing |
| `QUERIES_DIR` | `queries` | QUERIES_DIR indicates a directory for placing the query to be executed |
| `SCHEMA_DIR` | `schema` | Under `SCHEMA_DIR` is used for testing (when `EXEC_MODE = 'local'`).  The file name is assumed to be the same as the DB name |
| `SERVERS_INFO` | `servers.toml` | Server connection information (it must be a toml format file) |
| `MYSQL_USER`| `root` | Username of MySQL |
| `MYSQL_PASSWORD`| `"your_mysql_password"` | Password of MySQL |

### Server Information File
Sample is [Here](servers.toml).  
```
[service_name]
[service_name.mydb]
host_name = "<Hostname or IP address>"
port = <port number>
ssh_gateway = "<SSH username>@<SSH hostname>"
```
`mydb` is a key name that uniquely indicates the DB server and is used as the directory name of the place of the query.  (Describe later)  

### How to prepare execute SQL file
**Basic Rule**  

- 1 SQL file per 1 PR. (If you want to execute multiple queries to the same server, write it in 1 SQL file)  

**Path of the directory where files are placed**  

Example path: `service_name/mydb/file_name`    

File names are not related to execution. Just give it a unique name like `20190129_mytbl_update.sql`.  
