#
# ESTRUTURA
#

# criacao da estrutura de diretorio
mkdir -p ca/{root-ca,sub-ca,server}/{private,certs,newcerts,crl,csr}

# visualizacao da estrutura de diretorios
tree
.
├── ca
│   ├── root-ca
│   │   ├── certs
│   │   ├── crl
│   │   ├── csr
│   │   ├── newcerts
│   │   └── private
│   ├── server
│   │   ├── certs
│   │   ├── crl
│   │   ├── csr
│   │   ├── newcerts
│   │   └── private
│   └── sub-ca
│       ├── certs
│       ├── crl
│       ├── csr
│       ├── newcerts
│       └── private
└── doc


# alterando permissao
chmod -v 700 ca/{root-ca,sub-ca,server}/{private,certs,newcerts,crl,csr}

# arquivo de indice
touch ca/{root-ca,sub-ca}/index

# arquivo serial
openssl rand -hex 16 > ca/root-ca/serial
openssl rand -hex 16 > ca/sub-ca/serial

# visualizacao da estrutura de diretorio e arquivos
tree
.
├── ca
│   ├── root-ca
│   │   ├── certs
│   │   ├── crl
│   │   ├── csr
│   │   ├── index
│   │   ├── newcerts
│   │   ├── private
│   │   └── serial
│   ├── server
│   │   ├── certs
│   │   ├── crl
│   │   ├── csr
│   │   ├── newcerts
│   │   └── private
│   └── sub-ca
│       ├── certs
│       ├── crl
│       ├── csr
│       ├── index
│       ├── newcerts
│       ├── private
│       └── serial
└── doc
    └── README.md

#
# CHAVES PRIVADAS
#

# criacao das chaves privadas 
openssl genrsa -aes256 -out ca/root-ca/private/ca.key 4096 ; chave privada da rootCA
openssl genrsa -aes256 -out ca/sub-ca/private/sub-ca.key 4096 ; chave privada da subCA

openssl genrsa -out ca/server/private/server.key 2048 ; chave utilizada para criptografar o trafego

# estrutura de diretorio e arquivos
tree
.
├── ca
│   ├── root-ca
│   │   ├── certs
│   │   ├── crl
│   │   ├── csr
│   │   ├── index
│   │   ├── newcerts
│   │   ├── private
│   │   │   └── ca.key
│   │   └── serial
│   ├── server
│   │   ├── certs
│   │   ├── crl
│   │   ├── csr
│   │   ├── newcerts
│   │   └── private
│   │       └── server.key
│   └── sub-ca
│       ├── certs
│       ├── crl
│       ├── csr
│       ├── index
│       ├── newcerts
│       ├── private
│       │   └── sub-ca.key
│       └── serial
└── doc
    └── README.md

#
# CERTIFICADOS PUBLICO
#

# criacao do rootCA

# arquivo de configuracao
vi ca/root-ca/root-ca.conf

	default_ca	= ca_defaultault

	[CA_default]
	dir	                = /Users/cosmo/myprojects/howto/openssl/ca/root-ca
	certs               = $dir/certs
	crl_dir             = $dir/crl
	new_certs_dir       = $dir/newcerts
	database            = $dir/index
	serial              = $dir/serial
	RANDFILE            = $dir/private/.rand

	private_key         = $dir/private/ca.key
	certificate         = $dir/certs/ca.crt

	crlnumber           = $dir/crlnumber
	crl                 = $dir/crl/ca.crl
	crl_extensions      = crl_ext
	default_crl_days    = 30

	default_md          = sha256

	name_opt            = ca_default
	cert_opt            = ca_default
	default_days   		= 365
	preserve            = no
	policy              = policy_strict

	[ policy_strict ]
	countryName             = supplied
	stateOrProvinceName     = supplied
	organizationName        = match
	organizationalUnitName  = optional
	commonName              = supplied
	emailAddress            = optional

	[ policy_loose ]
	countryName         	= optional
	stateOrProvinceName  	= optional
	localityName        	= optional
	organizationName    	= optional
	organizationalUnitName  = optional
	commonName          	= supplied
	emailAddress        	= optional

	[ req ]
	# Options for the req tool, man req.
	default_bits		= 2048
	distinguished_name  = req_distinguished_name
	string_mask			= utf8only
	default_md			= sha256
	# Extension to add when the -x509 option is used.
	x509_extensions		= v3_ca

	[ req_distinguished_name ]
	countryName                 = Country Name (2 letter code)
	stateOrProvinceName         = State or Province Name
	localityName                = Locality Name
	0.organizationName          = Organization Name
	organizationalUnitName      = Organizational Unit Name
	commonName                  = Common Name
	emailAddress                = Email Address
	countryName_default  		= BR
	stateOrProvinceName_default = Brazil
	0.organizationName_default 	= Comics Ltd

	[ v3_ca ]
	# Extensions to apply when createing root ca
	# Extensions for a typical CA, man x509v3_config
	subjectKeyIdentifier	= hash
	authorityKeyIdentifier	= keyid:always,issuer
	basicConstraints		= critical, CA:true
	keyUsage 				= critical, digitalSignature, cRLSign, keyCertSign

	[ v3_intermediate_ca ]
	# Extensions to apply when creating intermediate or sub-ca
	# Extensions for a typical intermediate CA, same man as above
	subjectKeyIdentifier	= hash
	authorityKeyIdentifier  = keyid:always,issuer
	#pathlen​:0 ensures no more sub-ca can be created below an intermediate
	basicConstraints		= critical, CA:true, pathlen:0
	keyUsage 				= critical, digitalSignature, cRLSign, keyCertSign

	[ server_cert ]
	# Extensions for server certificates
	basicConstraints		= CA:FALSE
	nsCertType				= server
	nsComment				= "OpenSSL Generated Server Certificate"
	subjectKeyIdentifier	= hash
	authorityKeyIdentifier  = keyid,issuer:always
	keyUsage   				= critical, digitalSignature, keyEncipherment
	extendedKeyUsage  		= serverAuth

# certificado rootCA
openssl req -config ca/root-ca/root-ca.conf -key ca/root-ca/private/ca.key -new -x509 -days 7500 -sha256 -extensions v3_ca -out ca/root-ca/certs/ca.crt

# exibir o certificado
openssl x509 -noout -in ca/root-ca/certs/ca.crt -text

# Cartificados Publicos

# Criando uma CA Intermediaria

# Configuracao sub-ca
cp ca/root-ca/root-ca.conf ca/sub-ca/sub-ca.conf
vi ca/sub-ca/sub-ca.conf

	default_ca	= ca_defaultault

	[CA_default]
	dir	                = /Users/cosmo/myprojects/howto/openssl/ca/sub-ca
	certs               = $dir/certs
	crl_dir             = $dir/crl
	new_certs_dir       = $dir/newcerts
	database            = $dir/index
	serial              = $dir/serial
	RANDFILE            = $dir/private/.rand

	private_key         = $dir/private/sub-ca.key
	certificate         = $dir/certs/sub-ca.crt

	crlnumber           = $dir/crlnumber
	crl                 =  $dir/crl/ca.crl
	crl_extensions      = crl_ext
	default_crl_days    = 30

	default_md          = sha256

	name_opt            = ca_default
	cert_opt            = ca_default
	default_days   		= 365
	preserve            = no
	policy              = policy_loose

	[ policy_strict ]
	countryName             = supplied
	stateOrProvinceName     = supplied
	organizationName        = match
	organizationalUnitName  = optional
	commonName              = supplied
	emailAddress            = optional

	[ policy_loose ]
	countryName         	= optional
	stateOrProvinceName  	= optional
	localityName        	= optional
	organizationName    	= optional
	organizationalUnitName  = optional
	commonName          	= supplied
	emailAddress        	= optional

	[ req ]
	# Options for the req tool, man req.
	default_bits		= 2048
	distinguished_name  = req_distinguished_name
	string_mask			= utf8only
	default_md			= sha256
	# Extension to add when the -x509 option is used.
	x509_extensions		= v3_ca

	[ req_distinguished_name ]
	countryName                 = Country Name (2 letter code)
	stateOrProvinceName         = State or Province Name
	localityName                = Locality Name
	0.organizationName          = Organization Name
	organizationalUnitName      = Organizational Unit Name
	commonName                  = Common Name
	emailAddress                = Email Address
	countryName_default  		= BR
	stateOrProvinceName_default = Brazil
	0.organizationName_default 	= Comics Ltd

	[ v3_ca ]
	# Extensions to apply when createing root ca
	# Extensions for a typical CA, man x509v3_config
	subjectKeyIdentifier	= hash
	authorityKeyIdentifier	= keyid:always,issuer
	basicConstraints		= critical, CA:true
	keyUsage 				= critical, digitalSignature, cRLSign, keyCertSign

	[ v3_intermediate_ca ]
	# Extensions to apply when creating intermediate or sub-ca
	# Extensions for a typical intermediate CA, same man as above
	subjectKeyIdentifier	= hash
	authorityKeyIdentifier  = keyid:always,issuer
	#pathlen​:0 ensures no more sub-ca can be created below an intermediate
	basicConstraints		= critical, CA:true, pathlen:0
	keyUsage 				= critical, digitalSignature, cRLSign, keyCertSign

	[ server_cert ]
	# Extensions for server certificates
	basicConstraints		= CA:FALSE
	nsCertType				= server
	nsComment				=  "OpenSSL Generated Server Certificate"
	subjectKeyIdentifier	= hash
	authorityKeyIdentifier  = keyid,issuer:always
	keyUsage   				=  critical, digitalSignature, keyEncipherment
	extendedKeyUsage  		= serverAuth

# criacao do certificado
openssl req -config ca/sub-ca/sub-ca.conf -key ca/sub-ca/private/sub-ca.key -sha256 -out ca/sub-ca/csr/sub-ca.csr

openssl ca -config root-ca.conf -extensions v3_intermediate_ca -days 3650 -notext ca/sub-ca/csr/sub-ca.csr -out ca/sub-ca/certs/sub-ca.crt


