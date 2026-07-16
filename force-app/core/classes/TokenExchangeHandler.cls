public class TokenExchangeHandler extends Auth.Oauth2TokenExchangeHandler {

    private static String getIdpPublicKey() {
        List<TokenExchangeConfig__mdt> configs = [
            SELECT IdpPublicKey__c
            FROM TokenExchangeConfig__mdt
            LIMIT 1
        ];
        if (configs.isEmpty() || String.isBlank(configs[0].IdpPublicKey__c)) {
            throw new TokenExchangeException(
                'No IDP public key configured. Create a TokenExchangeConfig__mdt record with the IdpPublicKey__c field populated.'
            );
        }
        return configs[0].IdpPublicKey__c;
    }

    public override Auth.TokenValidationResult validateIncomingToken(
        String appDeveloperName,
        Auth.IntegratingAppType appType,
        String incomingToken,
        Auth.OAuth2TokenExchangeType tokenType
    ) {
        if (tokenType != Auth.OAuth2TokenExchangeType.JWT) {
            return new Auth.TokenValidationResult(false, null, null, incomingToken, tokenType, 'Expected a JWT token');
        }

        // Verify JWT signature
        String sigError = verifySignature(incomingToken);
        if (sigError != null) {
            return new Auth.TokenValidationResult(false, null, null, incomingToken, tokenType, sigError);
        }

        // Parse claims
        Map<String, Object> claims = parseJwtClaims(incomingToken);

        // Check expiration
        if (claims.containsKey('exp')) {
            Long exp = (Long) claims.get('exp');
            Long now = DateTime.now().getTime() / 1000;
            if (now > exp) {
                return new Auth.TokenValidationResult(false, null, null, incomingToken, tokenType, 'Subject token has expired');
            }
        }

        String email = (String) claims.get('email');
        String firstName = (String) claims.get('given_name');
        String lastName = (String) claims.get('family_name');
        String sub = (String) claims.get('sub');

        Auth.UserData userData = new Auth.UserData(
            null,                   // identifier
            firstName,              // firstName
            lastName,               // lastName
            null,                   // fullName
            email,                  // email
            null,                   // link
            sub,                    // username
            null,                   // locale
            (String) claims.get('iss'), // provider
            null,                   // siteLoginUrl
            null                    // attributeMap
        );

        return new Auth.TokenValidationResult(true, null, userData, incomingToken, tokenType, null);
    }

    public override User getUserForTokenSubject(
        Id networkId,
        Auth.TokenValidationResult result,
        Boolean canCreateUser,
        String appDeveloperName,
        Auth.IntegratingAppType appType
    ) {
        Auth.UserData userData = result.userData;

        // Look up existing user by email
        if (String.isNotBlank(userData.email)) {
            List<User> existing = [SELECT Id FROM User WHERE Email = :userData.email AND IsActive = true LIMIT 1];
            if (!existing.isEmpty()) {
                return existing[0];
            }
        }

        // Look up by username (sub claim)
        if (String.isNotBlank(userData.username)) {
            List<User> existing = [SELECT Id FROM User WHERE Username = :userData.username AND IsActive = true LIMIT 1];
            if (!existing.isEmpty()) {
                return existing[0];
            }
        }

        if (!canCreateUser) {
            return null;
        }

        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        String alias = String.isNotBlank(userData.email)
            ? userData.email.substringBefore('@')
            : userData.username;
        if (alias != null && alias.length() > 8) {
            alias = alias.substring(0, 8);
        }

        User u = new User(
            Email = userData.email,
            Username = userData.email + '.tokenexchange',
            FirstName = userData.firstName,
            LastName = String.isNotBlank(userData.lastName) ? userData.lastName : 'Unknown',
            Alias = alias,
            ProfileId = p.Id,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        insert u;
        return u;
    }

    // Returns null on success, or an error message string on failure
    private String verifySignature(String jwt) {
        List<String> parts = jwt.split('\\.');
        if (parts.size() != 3) {
            return 'Invalid JWT format';
        }

        String signingInput = parts[0] + '.' + parts[1];

        String sigB64 = parts[2];
        sigB64 = sigB64.replace('-', '+');
        sigB64 = sigB64.replace('_', '/');
        Integer remainder = Math.mod(sigB64.length(), 4);
        if (remainder == 2) sigB64 += '==';
        else if (remainder == 3) sigB64 += '=';

        Blob signature = EncodingUtil.base64Decode(sigB64);
        Blob publicKey = EncodingUtil.base64Decode(getIdpPublicKey());

        Boolean isValid = Crypto.verify(
            'RSA-SHA256',
            Blob.valueOf(signingInput),
            signature,
            publicKey
        );

        return isValid ? null : 'JWT signature verification failed';
    }

    public class TokenExchangeException extends Exception {}

    private Map<String, Object> parseJwtClaims(String jwt) {
        List<String> parts = jwt.split('\\.');
        if (parts.size() < 2) {
            return new Map<String, Object>();
        }
        String payload = parts[1];
        Integer remainder = Math.mod(payload.length(), 4);
        if (remainder == 2) payload += '==';
        else if (remainder == 3) payload += '=';
        payload = payload.replace('-', '+');
        payload = payload.replace('_', '/');

        String decoded = EncodingUtil.base64Decode(payload).toString();
        return (Map<String, Object>) JSON.deserializeUntyped(decoded);
    }
}
