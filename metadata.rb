name             'plm-haproxy'
maintainer       'PatientsLikeMe, Inc.'
maintainer_email 'cookbooks@patientslikeme.com'
license          'Apache 2.0'
description      'Installs/Configures plm-haproxy'
long_description 'Installs/Configures plm-haproxy'
version          '0.9.0'

issues_url       'https://github.com/patientslikeme/chef-plm-haproxy/issues' if respond_to?(:issues_url)
source_url       'https://github.com/patientslikeme/chef-plm-haproxy' if respond_to?(:source_url)

depends 'haproxy-ng'
depends 'yum-epel'
