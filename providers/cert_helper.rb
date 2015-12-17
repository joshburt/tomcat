###############################################################################
## action :install
## This action updates tomcat certificate, keystore, and ca chain as required
###############################################################################

action :install do
  ###############################################################################
  # We are requesting the creation/injection of a self-signed certificate.
  ###############################################################################
  if new_resource.ssl_cert_file.nil?
    execute 'Create Tomcat SSL certificate' do
      group new_resource.group
      command <<-EOH
#{node['tomcat']['keytool']} \
         -genkey \
         -keystore "#{new_resource.config_dir}/#{new_resource.keystore_file}" \
         -storepass "#{new_resource.keystore_password}" \
         -keypass "#{new_resource.keystore_password}" \
         -dname "#{node['tomcat']['certificate_dn']}" \
         -keyalg "RSA"
      EOH
      umask 0007
      #creates "#{new_resource.config_dir}/#{new_resource.keystore_file}"
      action :run
      notifies :restart, "service[#{new_resource.instance}]"
    end
  else
    ###############################################################################
    # We are being asked to use certificate artifacts provided (3rd-party)
    # but bundled within the cookbook.
    ##
    # Original implementation was no cross-platform, and could not execute
    # on Windows platforms.  This has been corrected.
    ###############################################################################

    # In Windows OpenSSL needs a little help to get going when launched through automation.
    if platform_family?('windows')
      env 'OPENSSL_CONF' do
        value "#{node['tomcat']['openssl_dir']}\\openssl.cnf"
      end
    end

    cookbook_file "#{new_resource.config_dir}/#{new_resource.ssl_cert_file}" do
      mode '0644'
      backup false
      notifies :stop, "service[#{new_resource.instance}]", :immediately
      notifies :run, "execute[create_keystore_add_chain_files-#{new_resource.instance}]"
    end

    cookbook_file "#{new_resource.config_dir}/#{new_resource.ssl_key_file}" do
      mode '0644'
      backup false
      notifies :stop, "service[#{new_resource.instance}]", :immediately
      notifies :run, "execute[create_keystore_add_chain_files-#{new_resource.instance}]"
    end

    cookbook_file "#{new_resource.config_dir}/#{new_resource.ssl_chain_files}" do
      mode '0644'
      backup false
      notifies :stop, "service[#{new_resource.instance}]", :immediately
      notifies :run, "execute[create_keystore_add_chain_files-#{new_resource.instance}]"
    end

    #new_resource.ssl_chain_files.each do |cert|
    execute "create_keystore_add_chain_files-#{new_resource.instance}" do
      command "\"#{node['tomcat']['cat']}\" #{new_resource.ssl_chain_files} > cacerts.pem"
      cwd new_resource.config_dir
      action :nothing
      notifies :stop, "service[#{new_resource.instance}]", :immediately
      notifies :run, "execute[create_keystore_add_cert_files-#{new_resource.instance}]"
    end

    # Note that this sets the keystore type to pkcs12, the node attribute keystore_type needs to be updated
    # accordingly if utilizing this functionality.
    execute "create_keystore_add_cert_files-#{new_resource.instance}" do
      Chef::Log.info '###############################################################################'
      Chef::Log.info "\"#{node['tomcat']['openssl']}\" pkcs12 -export -inkey #{new_resource.ssl_key_file} -in #{new_resource.ssl_cert_file} -chain -CAfile cacerts.pem -password pass:#{new_resource.keystore_password} -out #{new_resource.keystore_file}"
      Chef::Log.info '###############################################################################'
      command "\"#{node['tomcat']['openssl']}\" pkcs12 -export -inkey #{new_resource.ssl_key_file} -in #{new_resource.ssl_cert_file} -chain -CAfile cacerts.pem -password pass:#{new_resource.keystore_password} -out #{new_resource.keystore_file}"
      cwd new_resource.config_dir
      action :nothing
      notifies :stop, "service[#{new_resource.instance}]", :delayed
      notifies :start, "service[#{new_resource.instance}]", :delayed
    end
  end

  unless new_resource.truststore_file.nil?
    cookbook_file "#{new_resource.config_dir}/#{new_resource.truststore_file}" do
      mode '0644'
    end
  end
end