CREATE TABLE credentials (
	credential_id INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	username VARCHAR(255) UNIQUE NOT NULL,
	password VARCHAR(255) NOT NULL,
	role_id VARCHAR(255) NOT NULL,
	is_enabled BOOLEAN DEFAULT TRUE,
	is_account_non_expired BOOLEAN DEFAULT TRUE,
	is_account_non_locked BOOLEAN DEFAULT TRUE,
	is_credentials_non_expired BOOLEAN DEFAULT TRUE,
	user_id INT(11)
);

