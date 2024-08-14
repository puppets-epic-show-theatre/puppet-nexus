# @summary
#   Install and configure Sonatype Nexus Repository Manager 3.
#
# @see https://help.sonatype.com/repomanager3/product-information/download/download-archives---repository-manager-3
#
# @param download_folder
#   Destination folder of the downloaded archive.
# @param download_site
#   Download uri which will be appended with filename of the archive to download.
# @param install_root
#   The root filesystem path where the downloaded archive will be extracted to.
# @param work_dir
#   The nexus repository manager working directory which contains the embedded database and local blobstores.
# @param user
#   The operation system user used to start the nexus repository manager service.
# @param group
#   The operation system group used to start the nexus repository manager service.
# @param host
#   The bind address where the nexus repository manager service should bind to.
# @param port
#   The port which the nexus repository manager service should use.
# @param manage_api_resources
#   Set if this module should manage resources which require to be set over the nexus repository manager rest api.
# @param manage_config
#   Set if this module should manage the config file of nexus repository manager.
# @param manage_user
#   Set if this module should manage the creation of the operation system user.
# @param manage_work_dir
#   Set if this module should manage the work directory of the nexus repository manager.
# @param manage_datastore
#   Set if this module should manage datastore - ATM only postgresql is supported
# @param purge_installations
#   Set this option if you want old installations of nexus repository manager to get automatically deleted.
# @param purge_default_repositories
#   Set this option if you want to remove the default created maven and nuget repositories.
# @param package_type
#   Select 'src' for Source download & install. 'pkg' will fetch te specified package and version
#   from repos you must provide.
# @param package_ensure
#   The version to install. See https://puppet.com/docs/puppet/7/types/package.html#package-attribute-ensure
# @param download_proxy
#   Proxyserver address which will be used to download the archive file.
# @param version
#   The version to download, install and manage.
# @param java_runtime
#   The Java runtime to be utilized. Relevant only for Nexus versions >= 3.67.0-03 and < 3.71.0.
# @param package_name
#   The name of the package to install. Default 'nexus'
# @param postgresql_username
#   Postgresql Username
# @param postgresql_password
#   Postgresql Password
# @param postgresql_jdbcurl
#   Postgresql jdbcUrl. Formatted as jdbc\:postgresql\://<database-host>\:<database-port>/nexus
#
# @example
#   class{ 'nexus':
#     version => '3.37.3-02',
#   }
#
class nexus (
  Stdlib::Absolutepath $download_folder,
  Stdlib::HTTPUrl $download_site,
  Stdlib::Absolutepath $install_root,
  Stdlib::Absolutepath $work_dir,
  String[1] $user,
  String[1] $group,
  Stdlib::Host $host,
  Stdlib::Port $port,
  Boolean $manage_api_resources,
  Boolean $manage_config,
  Boolean $manage_user,
  Boolean $manage_work_dir,
  Boolean $manage_datastore,
  Boolean $purge_installations,
  Boolean $purge_default_repositories,
  Enum['src', 'pkg'] $package_type,
  String $package_ensure,
  Optional[Stdlib::HTTPUrl] $download_proxy = undef,
  Optional[Pattern[/3.\d+.\d+-\d+/]] $version = undef,
  Optional[Enum['java8', 'java11']] $java_runtime = undef,
  Optional[String] $package_name = undef,
  Optional[String[1]] $postgresql_username = undef,
  Optional[String[1]] $postgresql_password = undef,
  Optional[String[1]] $postgresql_jdbcurl = undef,
) {
  include stdlib

  if ($version and versioncmp($version, '3.67.0-03') >= 0 and versioncmp($version, '3.71.0') < 0 and ! $java_runtime) {
    fail('You need to define the $java_runtime parameter for nexus version >= 3.67.0-03 and < 3.71.0')
  }

  contain nexus::user
  contain nexus::package

  if $manage_config {
    contain nexus::config

    Class['nexus::package'] -> Class['nexus::config::properties'] ~> Class['nexus::service']
  }

  contain nexus::service

  Class['nexus::user'] -> Class['nexus::package'] ~> Class['nexus::service']

  Class['nexus::service']
  -> Nexus_user <| |>
  -> Nexus_setting <| |>
  -> Nexus_blobstore <| ensure == 'present' |>
  -> Nexus_repository <| |>
  -> Nexus_blobstore <| ensure == 'absent' |>
}
