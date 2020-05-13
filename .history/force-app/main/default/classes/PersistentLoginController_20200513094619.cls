/**
* An apex page controller that exposes the site login functionality that keeps users logged in
*/
global without sharing class PersistentLoginController {
    
    global String username {get; set;}
    global String password {get; set;}
    public String startURL {get; set;}
    
    global class passwordLessRet {
    	@AuraEnabled public String userId;
        @AuraEnabled public String identifier;
        @AuraEnabled public String error;
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
	
   @AuraEnabled(cacheable=false)
   global static String confirm(String userId, String identifier, String code, String startUrl) {
       String message = 'error in confirmation';
       String url = '';
       try {
       	Auth.VerificationResult res = System.UserManagement.verifyPasswordlessLogin(userId, Auth.VerificationMethod.EMAIL, identifier, code, '/s/');
       //system.debug(res);
       //aura.redirect(res.redirect);
            url = res.redirect.getUrl();
       //String encoded = EncodingUtil.urlEncode(url, 'UTF-8');
      		message =  res.message;
       } catch (Exception e) {
           
       }
       return url ;
	}       
    
    public class ResponseWrapper {
        public String userId;
        public String identifier;
        public String error;
    }

        
}