public class GrantRequestEditContactController {
    public FSTR__Business_Process__c thisBP {get;set;}
    public Boolean submitted {get;private set;}
    
    public GrantRequestEditContactController(){
        submitted = false;
        thisBP = new FSTR__Business_Process__c();
        
        if(ApexPages.currentPage().getParameters().containskey('grantid'))
            thisBP.Id = ApexPages.currentPage().getParameters().get('grantid');                
    }
    
    public PageReference SaveRecord(){
        try{            
            update thisBP;
        }catch (Exception ex){
            ApexPages.addMessages(ex);
            return null;            
        }  
        submitted = true;    
        return null;
    }   
    
}