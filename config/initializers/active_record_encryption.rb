# Keys for Active Record encryption (the SMTP password in Setting), derived from secret_key_base so no
# extra secrets are needed. Rotating secret_key_base makes stored values unreadable: re-enter them then.
# Keys set in credentials (active_record_encryption.*) take precedence.
#
# Runs when encryption is first used, after Rails has applied any keys from credentials,
# so building assets without a secret never touches it.
ActiveSupport.on_load(:active_record_encryption) do
  config = ActiveRecord::Encryption.config
  next if config.has_primary_key?

  derive = ->(salt) { Rails.application.key_generator.generate_key("active_record_encryption.#{salt}", 32).unpack1("H*") }
  config.primary_key = derive.("primary_key")
  config.deterministic_key = derive.("deterministic_key")
  config.key_derivation_salt = derive.("key_derivation_salt")
end
