# A description of what this class does
#
# @summary A short summary of the purpose of this class
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
      yumrepo { "mongodb-enterprise":
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
