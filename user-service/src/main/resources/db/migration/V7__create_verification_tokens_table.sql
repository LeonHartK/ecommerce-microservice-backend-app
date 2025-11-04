CREATE TABLE verification_tokens (
	verification_token_id INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	token VARCHAR(255) UNIQUE NOT NULL,
	expire_date TIMESTAMP NOT NULL,
	credential_id INT(11)
);

