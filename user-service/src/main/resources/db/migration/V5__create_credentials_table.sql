CREATE TABLE credentials (
	credential_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	username VARCHAR(255) NOT NULL UNIQUE,
	password VARCHAR(255) NOT NULL,
	role_id VARCHAR(255) NOT NULL,
	is_enabled BOOLEAN DEFAULT TRUE,
	is_account_non_expired BOOLEAN DEFAULT TRUE,
	is_account_non_locked BOOLEAN DEFAULT TRUE,
	is_credentials_non_expired BOOLEAN DEFAULT TRUE,
	user_id INT,
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	updated_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
CREATE INDEX idx_credentials_user_id ON credentials(user_id);

