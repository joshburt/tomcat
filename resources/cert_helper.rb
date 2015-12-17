actions :install
default_action :install


attribute :config_dir,
          kind_of: String
attribute :group,
          kind_of: String

attribute :ssl_cert_file,
          kind_of: String
attribute :ssl_key_file,
          kind_of: String

attribute :ssl_chain_files,
          kind_of: String

attribute :keystore_type,
          kind_of: String
attribute :keystore_file,
          kind_of: String
attribute :keystore_password,
          kind_of: String

attribute :truststore_file,
          kind_of: String

attribute :instance,
          kind_of: String
