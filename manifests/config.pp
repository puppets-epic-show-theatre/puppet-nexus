# @summary
#   Configure nexus repository manager
#
# @api private
#
class nexus::config {
  assert_private()

  contain nexus::config::properties

  if $nexus::manage_api_resources {
    class { 'nexus::config::admin':
      username      => $nexus::admin_username,
      first_name    => $nexus::admin_first_name,
      last_name     => $nexus::admin_last_name,
      email_address => $nexus::admin_email_address,
      roles         => $nexus::admin_roles,
      password      => $nexus::admin_password,
    }
    contain nexus::config::device
    contain nexus::config::anonymous
    contain nexus::config::email

    if $nexus::purge_default_repositories {
      contain nexus::config::default_repositories
    }

    Class['nexus::config::device']
    -> Class['nexus::config::admin']
    -> Class['nexus::config::anonymous']
    -> Class['nexus::config::email']
  }
}
