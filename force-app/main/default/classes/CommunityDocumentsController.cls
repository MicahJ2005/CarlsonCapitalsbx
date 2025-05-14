public with sharing class CommunityDocumentsController{

    public Map<string, List<ContentDocument>> docsByType{get;private set;}
    public Map<string, string> docGroupsByName{get;private set;}
    public List<string> orderedDesktopGroups {get;private set;}   
    public integer columns {get;private set;} 
    public User u {get;private set;}
    
    public CommunityDocumentsController(ApexPages.StandardController stdController){

        String ua=ApexPages.currentPage().getHeaders().get('User-Agent').toLowerCase();
        System.debug('user agent:' + ua);
        boolean mobile = false;
        columns = 2;
        Map<string, string> docSort = new Map<string, string>();
        if(ua.contains('mobi')){ 
            mobile = true;
            columns = 1;    
        }        
        DocumentGroupSettings__c docsettings = DocumentGroupSettings__c.getValues(UserInfo.getOrganizationId());        
        if(docsettings == null){
            docsettings = new DocumentGroupSettings__c();
            docsettings.Desktop_Group_Order__c = 'Quarterly Reports;Other Shared Documents';
            docsettings.Desktop_Public_Group_Order__c = 'Quarterly Newsletters;Compliance and Disclosures';       
        }
        //grab our sort orders
        if(docsettings.Document_Group_Sort_By__c != null){
            for(string s : docsettings.Document_Group_Sort_By__c.split(';')){
                List<string> splitDoc = s.split(':');
                if(splitDoc.size() == 3){
                    docSort.put(splitDoc[0], 'c.ContentDocument.' + splitDoc[1] + ' ' + splitDoc[2]);
                }
            }     
        }
        
        if(docsettings.Public_Document_Group_Sort_By__c != null){
            for(string s : docsettings.Public_Document_Group_Sort_By__c.split(';')){
                List<string> splitDoc = s.split(':');
                if(splitDoc.size() == 3){
                    docSort.put(splitDoc[0], 'c.ContentDocument.' + splitDoc[1] + ' ' + splitDoc[2]);
                }
            }     
        }
        
        //pull in all of the possible the group names into a list
        orderedDesktopGroups = new List<string>();
        List<string> localGroups =  new List<string>();
        localGroups.addall(docsettings.Desktop_Group_Order__c.split(';',0));
        List<string> localPublicGroups =  new List<string>();
        localPublicGroups.addall(docsettings.Desktop_Public_Group_Order__c.split(';',0));        
       
                
        id householdid;
        if(ApexPages.currentPage().getParameters().containskey('hid'))
            householdid = ApexPages.currentPage().getParameters().get('hid');
            
        u = [select contact.accountid, Portal_Upload_Allowed__c,Terms_Of_Use_Date__c from user where id = :Userinfo.getuserid()];
        System.debug(u);
        signTerms = u.Terms_Of_Use_Date__c==null ? true : false;
        if(u.contact.accountid != null)
             householdid  =  u.contact.accountid ;      
        
        //grab the document groups for the specified household
        if(householdid != null){                    
            docsByType = new Map<string, List<ContentDocument>> ();            
            docGroupsByName = new Map<string, string>();
            for(string s:  localGroups){
                docsByType.put(s, new List<ContentDocument>());
                docGroupsByName.put(s, '');                 
            } 
            for(string s:  localPublicGroups){
                docsByType.put(s, new List<ContentDocument>());
                docGroupsByName.put(s, '');                 
            }         
            for(Document_Group__c dgroup : [select id,type__c from Document_Group__c where Household__c = :householdid and Type__c in : localGroups]){                
                docGroupsByName.put(dgroup.type__c, dgroup.id);
                string dgid = dgroup.id;
                string sortBy = 'c.ContentDocument.Title DESC';
                if(docSort.containsKey(dgroup.type__c))
                    sortBy = docSort.get(dgroup.type__c);
                for(ContentDocumentLink cdl : Database.query('select c.ContentDocument.id, c.ContentDocument.Title, c.ContentDocument.LastModifiedDate, c.ContentDocument.LastModifiedBy.name, c.ContentDocumentId From ContentDocumentLink c WHERE LinkedEntityId = :dgid and c.contentdocument.FileExtension != \'.url\' order by ' + sortBy + ' limit 5')){
                   docsByType.get(dgroup.type__c).add(cdl.ContentDocument); 
                }
            }
            for(Document_Group_Public__c dgroup : [select id,name from Document_Group_Public__c where name in : localPublicGroups]){                
                docGroupsByName.put(dgroup.name, dgroup.id);
                string dgid = dgroup.id;
                string sortBy = 'c.ContentDocument.Title DESC';
                if(docSort.containsKey(dgroup.name))
                    sortBy = docSort.get(dgroup.name);
                for(ContentDocumentLink cdl : Database.query('select c.ContentDocument.id, c.ContentDocument.Title, c.ContentDocument.LastModifiedDate, c.ContentDocument.LastModifiedByid, c.ContentDocumentId From ContentDocumentLink c WHERE LinkedEntityId = :dgid and c.contentdocument.FileExtension != \'.url\' order by ' + sortBy + ' limit 5')){
                   docsByType.get(dgroup.name).add(cdl.ContentDocument); 
                }
            }
            //build the ordered list based on actual document counts
            list<string> localPopulatedGroups = new list<string>();                        
            for(string s : localGroups){
                if(!docsByType.get(s).isEmpty()){
                    localPopulatedGroups.add(s);
                }                
            }
            list<string> localPopulatedPublicGroups = new list<string>();                        
            for(string s : localPublicGroups){
                if(!docsByType.get(s).isEmpty()){
                    localPopulatedPublicGroups.add(s);
                }                
            }            
            if(!mobile){
                integer index = 0;
                integer maxCount = Math.Max(localPopulatedGroups.size(),localPopulatedPublicGroups.size());
                while (index < maxCount){                
                    if(index < localPopulatedGroups.size())
                        orderedDesktopGroups.add(localPopulatedGroups[index]);
                    else
                        orderedDesktopGroups.add('placeholder');
    
                    if(index < localPopulatedPublicGroups.size())
                        orderedDesktopGroups.add(localPopulatedPublicGroups[index]);                
                    else
                        orderedDesktopGroups.add('placeholder');                
                    index++;
                }           
            }
            else{
                for(string s : localPopulatedGroups){
                    orderedDesktopGroups.add(s);
                } 
                for(string s : localPopulatedPublicGroups){
                    orderedDesktopGroups.add(s);
                }               
            }               
        }            
    }    

    public Boolean signTerms {get;private set;}    
    // validation occurs in JS
    public PageReference agreeSubmit() {
        PageReference pr;
        u.Terms_Of_Use_Date__c=System.today();
        update u;
        pr = Page.CommunityDocuments;
        pr.setRedirect(true);
        return pr; // reload page
    }

}