# A class to manage the MongoDB YUM repo.
#
# @summary A class to manage the MongoDB YUM repo.
#
# @param gpgcheck Boolean to determine if GPG check is performed.
# @param baseurl The base URL for the repo.
# @param gpgkey The absolute path or source of the GPG key.
#
# @example
#   include mongodb::repos
class mongodb::repos (
  Boolean             $gpgcheck,
  Stdlib::Filesource  $baseurl,
  Stdlib::Filesource  $gpgkey,
) {

  case $facts['os']['family'] {
    'RedHat': {
      yumrepo { 'mongodb-enterprise':
        ensure   => present,
        baseurl  => $baseurl,
        descr    => 'MongoDB Enterprise Repository',
        gpgcheck => $gpgcheck,
        enabled  => true,
        gpgkey   => $gpgkey,
      }
    }
    default: {
      fail('This class if for RedHat only')
    }
  }
}
