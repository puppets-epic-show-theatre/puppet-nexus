# @summary Resource to manage yum proxy repository
#
# @param proxy_remote_url
#   yum repository url like https://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/.
# @param ensure
#   Define if the resource should be created/present or deleted/absent.
# @param http_client_auto_block
#   Auto-block outbound connections on the repository if remote peer is detected as unreachable/unresponsive.
# @param http_client_blocked
#   Block outbound connections on the repository.
# @param negative_cache_enabled
#   Cache responses for content not present in the proxied repository.
# @param negative_cache_time_to_live
#   How long to cache the fact that a file was not found in the repository (in minutes).
# @param online
#   Enable this repository in nexus repository manager that it can be used.
# @param proxy_content_max_age
#   Max age of content (packages)
# @param proxy_metadata_max_age
#   Max age of the repository metadata
# @param storage_blob_store_name
#   The name of the blobstore inside of nexus repository manager to be used. We suggest to use a own blobstore for each
#   defined repository.
# @param storage_strict_content_type_validation
#   Validate that all content uploaded to this repository is of a MIME type appropriate for the repository format.
# @param storage_write_policy
#   Controls if deployments of and updates to artifacts are allowed.
# @param cleanup_policy_names
#   Apply a list of cleanup policies to the repository. If a cleanup policy doesn't exist, nothing happens.
#
# @example
#   nexus::resource::repository::yum::proxy { 'yum-oracle-latest':
#      proxy_remote_url => 'https://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/',
#   }
#
define nexus::resource::repository::yum::proxy (
  Stdlib::HTTPSUrl $proxy_remote_url,
  Enum['present', 'absent'] $ensure = 'present',
  Boolean $http_client_auto_block = true,
  Boolean $http_client_blocked = false,
  Boolean $negative_cache_enabled = true,
  Integer $negative_cache_time_to_live = 1440,
  Boolean $online = true,
  Integer $proxy_content_max_age = 1440,
  Integer $proxy_metadata_max_age = 1440,
  String[1] $storage_blob_store_name = $title,
  Boolean $storage_strict_content_type_validation = true,
  Enum['ALLOW'] $storage_write_policy = 'ALLOW',
  Array[String[1]] $cleanup_policy_names = [],
) {
  nexus_repository { $title:
    ensure     => $ensure,
    format     => 'yum',
    type       => 'proxy',
    attributes => {
      'online'          => $online,
      'storage'         => {
        'blobStoreName'               => $storage_blob_store_name,
        'strictContentTypeValidation' => $storage_strict_content_type_validation,
        'writePolicy'                 => $storage_write_policy,
      },
      'cleanup'   => {
        'policyNames' => $cleanup_policy_names,
      },
      'proxy'           => {
        'remoteUrl'      => $proxy_remote_url,
        'contentMaxAge'  => $proxy_content_max_age,
        'metadataMaxAge' => $proxy_metadata_max_age,
      },
      'negativeCache'   => {
        'enabled'    => $negative_cache_enabled,
        'timeToLive' => $negative_cache_time_to_live,
      },
      'httpClient'      => {
        'blocked'        => $http_client_blocked,
        'autoBlock'      => $http_client_auto_block,
        'connection'     => {
          'retries'                 => undef,
          'userAgentSuffix'         => undef,
          'timeout'                 => undef,
          'enableCircularRedirects' => false,
          'enableCookies'           => false,
          'useTrustStore'           => false,
        },
        'authentication' => undef,
      },
      'routingRuleName' => undef,
    },
  }
}
