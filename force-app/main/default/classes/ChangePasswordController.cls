/**
 * An apex page controller that exposes the change password functionality
 */
public with sharing class ChangePasswordController {
    public String oldPassword {get; set;}
    public String newPassword {get; set;}
    public String verifyNewPassword {get; set;}        
    
    public PageReference changePassword() {
        return Site.changePassword(newPassword, verifyNewPassword, oldpassword);    
    }     
    
   	public ChangePasswordController() {}
    
    public PageReference setPassword() {
        integer i = Math.round(Math.random()*10000); 
        Blob targetBlob = Blob.valueOf(String.valueOf(i));
        Blob hash = Crypto.generateDigest('MD5', targetBlob);
        String randomPassword = EncodingUtil.base64Encode(hash);
        return Site.changePassword(randomPassword, randomPassword, oldpassword); 
    }
}