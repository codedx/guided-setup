function New-MariaDBNamespace([string] $namespace,
	[switch] $resourceFileOnly) {

	if (-not $resourceFileOnly -and (Test-Namespace $namespace)) {
		return
	}
	New-NamespaceResource $namespace -useGitOps:$resourceFileOnly
}

function New-MariaDBCredentialSecret([string] $namespace,
	[string] $name,
	[string] $rootPwd,
	[string] $replicatorPwd,
	[switch] $resourceFileOnly) {

	$credentials = @{
		'mariadb-root-password' = $rootPwd
	}

	if ('' -ne $replicatorPwd) {
		$credentials['mariadb-replication-password'] = $replicatorPwd
	}

	New-GenericSecretResource $namespace $name -keyValues $credentials -useGitOps:$resourceFilesOnly
}

function New-MariaDBOptionConfigMap([string] $namespace,
	[string] $name,
	[string] $characterSet,
	[string] $collation,
	[int]    $lowerCaseTableNames,
	[int]    $binaryLogExpirationSeconds,
	[switch] $resourceFileOnly) {

	$dbConfig = @'
[mysqld]
skip-name-resolve
explicit_defaults_for_timestamp
basedir=/opt/bitnami/mariadb
plugin_dir=/opt/bitnami/mariadb/plugin
port=3306
socket=/opt/bitnami/mariadb/tmp/mysql.sock
tmpdir=/opt/bitnami/mariadb/tmp
max_allowed_packet=16M
bind-address=*
pid-file=/opt/bitnami/mariadb/tmp/mysqld.pid
log-error=/opt/bitnami/mariadb/logs/mysqld.log
slow_query_log=0
slow_query_log_file=/opt/bitnami/mariadb/logs/mysqld.log
long_query_time=10.0
character-set-server={0}
collation-server={1}
lower_case_table_names={2}
binlog_expire_logs_seconds={3}

[client]
port=3306
socket=/opt/bitnami/mariadb/tmp/mysql.sock
default-character-set=UTF8
plugin_dir=/opt/bitnami/mariadb/plugin

[manager]
port=3306
socket=/opt/bitnami/mariadb/tmp/mysql.sock
pid-file=/opt/bitnami/mariadb/tmp/mysqld.pid
'@

	$dbConfigFile = 'db.cnf'
	$dbConfig -f $characterSet,$collation,$lowerCaseTableNames,$binaryLogExpirationSeconds | out-file $dbConfigFile -Encoding ascii -Force

	New-ConfigMapResource $namespace $name -fileKeyValues @{ 'my.cnf' = $dbConfigFile } -useGitOps:$resourceFileOnly
}