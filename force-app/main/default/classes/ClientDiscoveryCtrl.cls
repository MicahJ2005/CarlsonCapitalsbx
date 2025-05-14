/**
* @author Orchestrate LLC
* @date 2016
*
* @group Controllers
*
* @description Client Discovery page controller extension
*/
public with sharing class ClientDiscoveryCtrl {

  public List<Client_Discovery_Item__c> heirItems {get;set;}
  private Map<String,String> rtIdByName;


  public Integer pageNumber {get;private set;}
  public Integer totalPages {get;private set;}  
  public List<ItemWrapper> lifeGoals {get;set;}

  private Id discoveryId;
  private final Discover_Questionnaire__c questionnaire;

  private ApexPages.StandardController sc;

  public Integer lastSavedMinutesAgo {get;set;}

  public String itemId {get;set;}

  public Map<String,List<String>> picklistValuesByFieldName {get;private set;}

  private Boolean isPDF = false;
  //private String clientId;
  private String retURL;
  public Boolean isReadOnly {get;private set;}
  public Boolean isCoClient {get;private set;}
  private User currentUser;

  public ClientDiscoveryCtrl(ApexPages.StandardController sc) {
    populatePicklistValues();
    if (ApexPages.currentPage().getParameters().get('pdf')!=null) {
      this.isPDF = Boolean.valueOf(ApexPages.currentPage().getParameters().get('pdf'));
    }    
    isReadOnly = false;
    if (UserInfo.getUserType()=='Standard' && !Test.isRunningTest()) {
      isReadOnly = true;
    }
    currentUser = [Select Name,FirstName,LastName,Email,ContactId,Contact.AccountId,Portal_Notification_Emails__c From User Where Id=:UserInfo.getUserId() Limit 1];
    this.retURL = ApexPages.currentPage().getParameters().get('retURL');
    isCoClient = false;
    pageNumber = 2; 
    totalPages = 8;
    lastSavedMinutesAgo = 0;
    this.sc = sc;
    questionnaire = (Discover_Questionnaire__c)sc.getRecord();
    discoveryId = sc.getId();

    queryClientGoals();
    initialize();

    if (ApexPages.currentPage().getParameters().get('coclient')!=null && ApexPages.currentPage().getParameters().get('coclient')=='true') {
      isCoClient = true;
    }
  }

  public PageReference redirectToCoClient() {
    PageReference pr = Page.ClientDiscovery;
    pr.getParameters().put('coclient','true');
    return pr.setRedirect(true);
  }

  public PageReference onPageLoad() {
    // query for existing or create new on page load
    if (sc.getId()==null && !isReadOnly) {
      Discover_Questionnaire__c clientDiscovery;
      // insert a new client inventory if one does not existing for this user (can be two - client and co-client)
      if ([Select count() From Discover_Questionnaire__c Where CreatedById=:currentUser.Id and IsCoClient__c=:isCoClient]==0) {
        clientDiscovery = new Discover_Questionnaire__c(CreatedById=currentUser.Id,Name=currentUser.LastName+', '+currentUser.FirstName,IsCoClient__c=isCoClient,Household__c=currentUser.Contact.AccountId);
        insert clientDiscovery;
      } else {
        // query for client or co-client version of the questionnairre
        clientDiscovery = [Select Id From Discover_Questionnaire__c Where CreatedById=:currentUser.Id and IsCoClient__c=:isCoClient Limit 1];
      }
      discoveryId = clientDiscovery.Id;
      PageReference pr = Page.ClientDiscovery;
      pr.getParameters().put('id',clientDiscovery.Id);
      pr.getParameters().put('coclient',String.valueOf(isCoClient));
      return pr.setRedirect(true);
      // redirect page to this page
    } else if (UserInfo.getUserType()!='CspLitePortal') {
      ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'This page is editable only by client portal users.'));
    }
    return null;
  }  

  private void initialize() {
    // set records types
    rtIdByName = new Map<String,String>();
    List<RecordType> rts = [Select Name 
                From RecordType 
                Where SobjectType='Client_Discovery_Item__c' 
                  and Name in ('Heir')];
    for (RecordType r : rts) {
      rtIdByName.put(r.Name.toLowerCase(),r.Id);
    }

    queryItemRecords();

    if (heirItems.size()==0) {
      heirItems.add(new Client_Discovery_Item__c(Client_Discovery_Questionnaire__c=discoveryId,RecordTypeId=rtIdByName.get('heir')));
    }            
  }


  private void populatePicklistValues() {
    picklistValuesByFieldName = new Map<String,List<String>>();
    Map<String, Schema.sobjecttype> gd = Schema.getGlobalDescribe();
    Schema.DescribeSObjectResult r = gd.get('discover_questionnaire__c').getDescribe(); 
    Map<String, Schema.SObjectField> fieldMap = r.fields.getMap();
    for (String fieldName : fieldMap.keySet()) {
      // get values and add each to a list of strings
      List<Schema.PicklistEntry> values = fieldMap.get(fieldName).getDescribe().getPicklistValues();
      List<String> entries = new List<String>();
      for (Schema.PicklistEntry p : values) {
        entries.add(p.getLabel());
      }
      // if there are picklist values add to the map
      if (!entries.isEmpty()) {
        picklistValuesByFieldName.put(fieldName,entries);    
      }
    }
  }


  private void queryItemRecords() {
    // query for related records if the inventory has been created
    heirItems = getItemRecords(discoveryId,'Heir');
  }

  // DML METHODS

  public PageReference saveGoalItems() {
    attemptSave(lifeGoals);
    queryClientGoals();

    return null;
  }  

  public PageReference addGoalItem() {
    attemptSave(lifeGoals);
    queryClientGoals();
    lifeGoals.add(new ItemWrapper(new Life_Goal__c(Client_Discovery_Questionnaire__c=sc.getId())));

    return null;
  }    

  public PageReference removeGoalItem() {
    if (itemId!=null && itemId!='') {
      delete [Select Id From Life_Goal__c Where Id=:itemId];
      queryClientGoals();
      itemId = null;
    } else {
      queryClientGoals();
    }

    return null;
  }

  //

  public PageReference saveHeirItems() {
    // save and query for items
    attemptItemSave(heirItems);
    heirItems = getItemRecords(discoveryId,'Heir');

    return null;
  }  

  public PageReference addHeirItems() {
    // save and add a new item
    attemptItemSave(heirItems);
    heirItems.add(new Client_Discovery_Item__c(Client_Discovery_Questionnaire__c=discoveryId,RecordTypeId=rtIdByName.get('heir')));

    return null;
  }  

  public PageReference removeHeirItem() {
    if (itemId!=null && itemId!='') {
      delete [Select Id From Client_Discovery_Item__c Where Id=:itemId];
      queryItemRecords();
      itemId = null;
    } else {
      queryItemRecords();
    }

    return null;
  }


  // query for a list of records related to this inventory id if it already exists
  private List<Client_Discovery_Item__c> getItemRecords(String discoveryId,String recordTypeName) {
    List<Client_Discovery_Item__c> retList = new List<Client_Discovery_Item__c>();
    try {
      retList = [Select Name,Date__c,Age__c,Description__c,Status__c,Tax_Id__c
          From Client_Discovery_Item__c 
          Where Client_Discovery_Questionnaire__c=:discoveryId and RecordType.Name=:recordTypeName];
    } catch (Exception e) {
      System.debug('Error retrieving records '+e.getMessage()+'; '+e.getStackTraceString());
    }

    return retList;
  }

  private void attemptItemSave(List<Client_Discovery_Item__c> items) {
    try {
      upsert items;
    } catch (Exception e) {
      System.debug(e.getMessage());
    }    
  }

  // MASTER SAVE METHOD 
  public PageReference quickSaveItems() {
    saveQuestionnaire();

    return null;
  }  

  public PageReference saveAndExit() {
    saveQuestionnaire();
    return new PageReference(retURL!=null?retURL:'/');
  }    

  // auto-save to ensure data is not lost here
  public PageReference autoSave() {
    //questionnaire.AutoSaved__c = System.now();
    saveQuestionnaire();

    return null;
  }

  public PageReference updateLastSaved() {
    lastSavedMinutesAgo+=1;
    return null;
  }


  public PageReference completeApplication() {
    //insert createQueueTask('Client Discovery Questionnaire');
    //Utility.createQueueTask('Client Discovery',discoveryId,currentUser.Contact.AccountId,currentUser.ContactId,currentUser.FirstName+' '+currentUser.LastName);
    //Utility.sendNotificationEmail('Client Discovery',discoveryId,currentUser.FirstName,currentUser.LastName,currentUser.Portal_Notification_Emails__c);
      Map<String,Boolean> triggerMap = new Map<String,Boolean>{
          'isComplete'=>true
      };
      Utility.sendClientInformationNotification(new Set<Id>{discoveryId},triggerMap,'discover_questionnaire__c');    
    return saveAndExit();    
  }   
  
  // PRIVATE METHODS

  private void saveQuestionnaire() {
    // set savepoint for all operations
    if (!isReadOnly) {
      SavePoint sp = Database.setSavePoint();
      try {
        questionnaire.Household__c = currentUser.Contact.AccountId;
        upsert questionnaire;
        attemptSave(lifeGoals);
        attemptItemSave(heirItems);
        heirItems = getItemRecords(discoveryId,'Heir');
        lastSavedMinutesAgo = 0;
      } catch (Exception e) {
        Database.rollback(sp);
      }  
    }  
  }

  private void attemptSave(List<ItemWrapper> items) {
    Boolean isSuccess = discoveryId!=null;
    try {
      List<Life_Goal__c> upsertItems = new List<Life_Goal__c>();
      List<Life_Goal__c> deleteItems = new List<Life_Goal__c>();
      for (ItemWrapper i : items) {
        if (!i.RemoveItem) {
          upsertItems.add(i.item);
        } else if (i.RemoveItem && i.item.Id!=null) {
          deleteItems.add(i.item);
        }
      }  
      upsert upsertItems;
      delete deleteItems;
    } catch (Exception e) {
      isSuccess = false;
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                            'Problem saving your new Item(s). '+e.getMessage()));
    }    
  }  

  private void queryClientGoals() {
    lifeGoals = new List<ItemWrapper>();
    try {
      for (Life_Goal__c g : [Select Name,Type__c,Priority__c,Time_Frame__c,Goal__c 
          From Life_Goal__c 
          Where Client_Discovery_Questionnaire__c = :sc.getId() 
          Order By Type__c]) {
        lifeGoals.add(new ItemWrapper(g));
      }        
    } catch (Exception e) {
      //lifeGoals = new List<ItemWrapper>();
    }      
  }   

  // PAGE NAVIGATION

  //public PageReference page1() {
  //  saveQuestionnaire();
  //  pageNumber = 1;

  //  return null;
  //}  

  public PageReference page2() {
    saveQuestionnaire();
    pageNumber = 2;

    return null;
  }  

  public PageReference page3() {
    saveQuestionnaire();
    pageNumber = 3;

    return null;
  }  

  public PageReference page4() {
    saveQuestionnaire();
    pageNumber = 4;

    return null;
  }  

  public PageReference page5() {
    saveQuestionnaire();
    pageNumber = 5;

    return null;
  }    

  public PageReference page6() {
    saveQuestionnaire();
    pageNumber = 6;

    return null;
  }  

  public PageReference page7() {
    saveQuestionnaire();
    pageNumber = 7;

    return null;
  }  

  public PageReference page8() {
    saveQuestionnaire();
    pageNumber = 8;

    return null;
  }            

  public PageReference priorPage() {
    saveQuestionnaire();
    if (pageNumber>2) {
      pageNumber--;  
    }

    return null;
  }

  public PageReference nextPage() {
    saveQuestionnaire();
    if (pageNumber<totalPages) {
      pageNumber++;  
    }
    return null;
  }      

    // WRAPPER CLASS FOR REMOVING ITEMS

  public class ItemWrapper {
    public Boolean RemoveItem {get;set;}
    public Life_Goal__c item {get;set;}

    public ItemWrapper(Life_Goal__c i) {
      this.item = i;
      this.RemoveItem = false;
    }
  }


}