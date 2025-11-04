CREATE TABLE verification_tokens (
	verification_token_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	token VARCHAR(255) NOT NULL UNIQUE,
	expire_date TIMESTAMP NOT NULL,
	credential_id INT NOT NULL,
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
CREATE INDEX idx_verif_tokens_credential_id ON verification_tokens(credential_id);

