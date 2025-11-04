CREATE TABLE address (
    address_id INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
    full_address VARCHAR(255),
    postal_code VARCHAR(255),
    city VARCHAR(255),
    user_id INT(11)
);


