# @summary
#   Install and configure Sonatype Nexus Repository Manager 3.
#
# @see https://help.sonatype.com/repomanager3/product-information/download/download-archives---repository-manager-3
#
# @param version
#   The version to download, install and manage.
# @param download_folder
#   Destination folder of the downloaded archive.
# @param download_site
#   Download uri which will be appended with filename of the archive to download.
# @param download_proxy
#   Proxyserver address which will be used to download the archive file.
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
# @param purge_installations
#   Set this option if you want old installations of nexus repository manager to get automatically deleted.
# @param purge_default_repositories
#   Set this option if you want to remove the default created maven and nuget repositories.
# @param package_type
#   Select 'src' for Source download & install. 'pkg' will fetch te specified package and version
#   from repos you must provide.
# @param package_name
#   The name of the package to install. Default 'nexus'
# @param package_ensure
#   The version to install. See https://puppet.com/docs/puppet/7/types/package.html#package-attribute-ensure
#
# @example
#   class{ 'nexus':
#     version => '3.37.3-02',
#   }
#
class nexus (
  Optional[Pattern[/3.\d+.\d+-\d+/]] $version,
  Stdlib::Absolutepath $download_folder,
  Stdlib::HTTPUrl $download_site,
  Optional[Stdlib::HTTPUrl] $download_proxy,
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
  Boolean $purge_installations,
  Boolean $purge_default_repositories,
  Enum['src', 'pkg'] $package_type,
  Optional[String] $package_name,
  String $package_ensure,
) {
  include stdlib

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
