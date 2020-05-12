/**
* An apex page controller that exposes the site login functionality that keeps users logged in
*/
global without sharing class PersistentLoginController {
    private static final String CLIENT_ID = '3MVG9tzQRhEbH_K1MMend4CE2_3sNUnyCiqxEP1U0r2MpNI0G4tfzwATVosImbtEO98MwuHE1uQ.WJzOsMQMq';
    private static final Integer VALIDITY = 31536000;
    
    global String username {get; set;}
    global String password {get; set;}
    public String startURL {get; set;}
    public String m {get; set;}
    
    global PersistentLoginController() {}
    
    @AuraEnabled(cacheable=true)
    global static String loginLWC(String username, String password, String startUrl) {
        ResponseJSONWrapper response = new ResponseJSONWrapper();
        PageReference loginResult = Site.login(username, password, startUrl);
        if (loginResult != null) {
            response.retURL = loginResult.getUrl();
            response.JWT = getJWT(username);
            response.tokenEndpoint = Site.getBaseSecureUrl() + '/services/oauth2/token';
        } else {
            response.error = 'error';
        }
        aura.redirect(loginResult);
        return JSON.serialize(response);
    }
    
    @AuraEnabled(cacheable=true)
    global static passwordLessRet passwordless(String input, String startURL) { 
        String error = '';
        String identifier = '';
        ID uid;
        try {
            List<User> users = null;
            if(input == null || input == '')
            {
                error = 'Enter Username';
            }   
            users = [select name, id, email from User where username=:input];
            if(users == null || users.isEmpty())
            {
                error = 'Can\'t find a user';            
                return null;
            }  
            uid = users[0].id;
            if (startURL == null) startURL = '/';  
            
            identifier = System.UserManagement.initPasswordlessLogin(uid, Auth.VerificationMethod.EMAIL);
        } catch (Exception e) {
            error += e.getMessage();   
        }
        passwordLessRet ret = new passwordLessRet();
        ret.userId = uid;
        ret.identifier = identifier;
        ret.error = error;
        return ret;
        //return Site.passwordlessLogin(uid, methods, startURL);
    }
    
    
    global class passwordLessRet {
    	@AuraEnabled public String userId;
        @AuraEnabled public String identifier;
        @AuraEnabled public String error;
    }
	
   @AuraEnabled(cacheable=false)
   global static String confirm(String userId, String identifier, String code, String startUrl) {
       String message = 'error in confirmation';
       try {
       	Auth.VerificationResult res = System.UserManagement.verifyPasswordlessLogin(userId, Auth.VerificationMethod.EMAIL, identifier, code, '/consumer/s/');
       //system.debug(res);
       //aura.redirect(res.redirect);
       //String url = res.redirect.getUrl();
       //String encoded = EncodingUtil.urlEncode(url, 'UTF-8');
      		message =  res.message;
       } catch (Exception e) {
           
       }
       return 'message:'+message;
	}     
    
    @AuraEnabled(cacheable=true)
    global static String passwordlessLWC(String input, String startURL) { 
        ResponseWrapper ret = new ResponseWrapper();
        String error = '';
        String identifier = '';
        ID uid;
        try {
            List<User> users = null;
            users = [select name, id, email from User where username=:input];
            uid = users[0].id;
            identifier = System.UserManagement.initPasswordlessLogin(uid, Auth.VerificationMethod.EMAIL);
        } catch (Exception e) {
            error += e.getMessage();   
        }
        ret.userId = uid;
        ret.identifier = identifier;
        ret.error = error;
        return JSON.serialize(ret);
    }    
    
    public class ResponseWrapper {
        public String userId;
        public String identifier;
        public String error;
    }
    
    public class ResponseJSONWrapper {
        public String retURL;
        public String JWT;
        public String tokenEndpoint;
        public String error;
    }
    
    private static String getJWT(String username) {
        JWT jwt = new JWT('RS256');
        jwt.sub = username;
        jwt.aud = Site.getBaseSecureUrl();
        jwt.iss = CLIENT_ID;
        jwt.cert = 'userJWT';
        return jwt.issue();
    }
    
    global PageReference login() {
        PageReference loginResult = Site.login(username, password, startUrl);
        if (loginResult != null) {
            Auth.JWT jwt = new Auth.JWT();
            jwt.setSub(username);
            jwt.setAud(Site.getBaseSecureUrl());
            jwt.setIss(CLIENT_ID);
            Auth.JWS jws = new Auth.JWS(jwt, 'userJWT');
            Cookie token = new Cookie('token',jws.getCompactSerialization(),null,VALIDITY,true);
            ApexPages.currentPage().setCookies(new Cookie[]{token});
        }
        return loginResult;
    }
    
    
    class JWT {
        
        public String alg {get;set;}
        public String iss {get;set;}
        public String sub {get;set;}
        public String aud {get;set;}
        public String exp {get;set;}
        public String iat {get;set;}
        public Map<String,String> claims {get;set;}
        public Integer validFor {get;set;}
        public String cert {get;set;}
        public String pkcs8 {get;set;}
        public String privateKey {get;set;}
        
        
        public final String HS256 = 'HS256';
        public final String RS256 = 'RS256';
        public final String NONE = 'none';
        
        
        public JWT(String alg) {
            this.alg = alg;
            this.validFor = 31536000;
        }
        
        
        public String issue() {
            
            String jwt = '';
            
            JSONGenerator header = JSON.createGenerator(false);
            header.writeStartObject();
            header.writeStringField('alg', this.alg);
            header.writeEndObject();
            String encodedHeader = base64URLencode(Blob.valueOf(header.getAsString()));
            
            JSONGenerator body = JSON.createGenerator(false);
            body.writeStartObject();
            body.writeStringField('iss', this.iss);
            body.writeStringField('sub', this.sub);
            body.writeStringField('aud', this.aud);
            Long rightNow = (dateTime.now().getTime()/1000)+1;
            body.writeNumberField('iat', rightNow);
            body.writeNumberField('exp', (rightNow + validFor));
            if (claims != null) {
                for (String claim : claims.keySet()) {
                    body.writeStringField(claim, claims.get(claim));
                }
            }
            body.writeEndObject();
            
            jwt = encodedHeader + '.' + base64URLencode(Blob.valueOf(body.getAsString()));
            
            if ( this.alg == HS256 ) {
                Blob key = EncodingUtil.base64Decode(privateKey);
                Blob signature = Crypto.generateMac('hmacSHA256',Blob.valueof(jwt),key);
                jwt += '.' + base64URLencode(signature);
            } else if ( this.alg == RS256 ) {
                Blob signature = null;
                
                if (cert != null ) {
                    signature = Crypto.signWithCertificate('rsa-sha256', Blob.valueOf(jwt), cert);
                } else {
                    Blob privateKey = EncodingUtil.base64Decode(pkcs8);
                    signature = Crypto.sign('rsa-sha256', Blob.valueOf(jwt), privateKey);
                }
                jwt += '.' + base64URLencode(signature);
            } else if ( this.alg == NONE ) {
                jwt += '.';
            }
            
            return jwt;
            
        }
        
        
        public String base64URLencode(Blob input){
            String output = encodingUtil.base64Encode(input);
            output = output.replace('+', '-');
            output = output.replace('/', '_');
            while ( output.endsWith('=')){
                output = output.subString(0,output.length()-1);
            }
            return output;
        }
        
        
    }
    
}