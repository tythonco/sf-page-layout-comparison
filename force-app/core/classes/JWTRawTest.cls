// Credit: Shared by Salesforce (Chirag Mehta & Daniel Ballinger)
// See: https://partners.salesforce.com/0694V00000NCWhr
@isTest
public class JWTRawTest {
    static string dummyKey =
        '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';

    @TestSetup
    static void setup() {
        dummyKey = dummyKey.replace('\n', '');
    }

    @IsTest
    static void testJWT() {
        JWTRaw jwt = new JWTRaw('RS256');
        jwt.pkcs8 = dummyKey;
        jwt.iss = 'dummyClientSecret';
        jwt.sub = 'foo@user.com';
        jwt.aud = 'https://dummy.com';

        string minted = jwt.issue();

        Assert.isNotNull(minted);
    }
}