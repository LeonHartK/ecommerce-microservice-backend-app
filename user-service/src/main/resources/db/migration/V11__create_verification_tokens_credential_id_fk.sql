ALTER TABLE verification_tokens
  ADD CONSTRAINT fk_verification_tokens_credential
  FOREIGN KEY (credential_id) REFERENCES credentials(credential_id)
  ON DELETE CASCADE ON UPDATE CASCADE;
