/**
* @author Orchestrate LLC
* @date 2016
*
* @group Controllers
*
* @description Client Inventory page controller
*/
public with sharing class ClientInventoryCtrl {

  public List<ItemWrapper> incomeItems {get;set;}
  public List<ItemWrapper> networthItems {get;set;}
  public List<ItemWrapper> debtItems {get;set;}
  public List<ItemWrapper> dependentItems {get;set;}
  public List<ItemWrapper> savingsItems {get;set;}

  // private variables
  private Map<String,String> rtIdByName;

  private ApexPages.StandardController sc;
  private final Client_Inventory__c inventory;
  private String inventoryId;

  public Integer pageNumber {get;private set;}
  public Integer totalPages {get;private set;}

  public Integer lastSavedMinutesAgo {get;set;}
  public String itemId {get;set;}

  private Boolean isPDF = false;
  //private String clientId;
  private String retURL;
  private User currentUser;

  public List<Attachment> attachments01 {get;private set;}
  public List<Attachment> attachments02 {get;private set;}
  public List<Attachment> attachments03 {get;private set;}
  public List<Attachment> attachments04 {get;private set;}
  public List<Attachment> attachments05 {get;private set;}
  public List<Attachment> attachments06 {get;private set;}
  public List<Attachment> attachments07 {get;private set;}
  public List<Attachment> attachments08 {get;private set;}
  public List<Attachment> attachments09 {get;private set;}
  public List<Attachment> attachments10 {get;private set;}
  public List<Attachment> attachments11 {get;private set;}
  public List<Attachment> attachments12 {get;private set;}
  public List<Attachment> attachments13 {get;private set;}
  public List<Attachment> attachments14 {get;private set;}

  public List<Attachment> allAttachments {get;private set;}
  public List<Attachment> clientOtherAttachments {get;private set;}
  public List<Attachment> otherAttachments {get;private set;}
  public List<ContentDocumentLink> otherDocuments {get;private set;}

  public String attachmentType {get;set;}
  public Boolean isReadOnly {get;private set;}

    public Attachment attachment {
      get {
        if (attachment == null)
          attachment = new Attachment();
        return attachment;
      }
      set;
    }  

  public ClientInventoryCtrl(ApexPages.StandardController sc) {
    if (ApexPages.currentPage().getParameters().get('pdf')!=null) {
      this.isPDF = Boolean.valueOf(ApexPages.currentPage().getParameters().get('pdf'));
    }
    isReadOnly = false;
    if (UserInfo.getUserType()=='Standard' && !Test.isRunningTest()) {
      isReadOnly = true;
    } else {
      currentUser = [Select Name,FirstName,LastName,Email,ContactId,Contact.AccountId,Portal_Notification_Emails__c From User Where Id=:UserInfo.getUserId() Limit 1];
    }    
    this.retURL = ApexPages.currentPage().getParameters().get('retURL');
    this.sc = sc;
    pageNumber = 1; //TODO page number based on last selected by user
    totalPages = 7;
    lastSavedMinutesAgo = 0;
    inventory = (Client_Inventory__c)sc.getRecord();
    System.debug(inventory);
    inventoryId = sc.getId();
    System.debug(inventoryId);

    initialize();
    queryAttachments();
  }

  private void initialize() {
    // set records types
    rtIdByName = new Map<String,String>();
    List<RecordType> rts = [Select Name 
                From RecordType 
                Where SobjectType='Client_Inventory_Item__c' 
                  and Name in ('Debt','Income','Net Worth','Dependent','Savings')];
    for (RecordType r : rts) {
      rtIdByName.put(r.Name.toLowerCase(),r.Id);
    }    
    
    queryItemRecords();    

    if (incomeItems.size()==0) {
      incomeItems.add(new ItemWrapper(new Client_Inventory_Item__c(RecordTypeId=rtIdByName.get('income'))));
    }
    if (networthItems.size()==0) {
      networthItems.add(new ItemWrapper(new Client_Inventory_Item__c(RecordTypeId=rtIdByName.get('net worth'))));
    }
    if (debtItems.size()==0) {
      debtItems.add(new ItemWrapper(new Client_Inventory_Item__c()));
    }
    if (dependentItems.size()==0) {
      dependentItems.add(new ItemWrapper(new Client_Inventory_Item__c(RecordTypeId=rtIdByName.get('dependent'))));
    }
    if (savingsItems.size()==0) {
      savingsItems.add(new ItemWrapper(new Client_Inventory_Item__c(RecordTypeId=rtIdByName.get('savings'))));
    }    

  }

  public PageReference onPageLoad() {
    // query for existing or create new on page load
    if (sc.getId()==null && !isReadOnly) {
      //User u = [Select Name,LastName,FirstName From User Where Id=:UserInfo.getUserId()];
      Client_Inventory__c clientInv;
      // insert a new client inventory if one does not existing for this user
      if ([Select count() From Client_Inventory__c Where CreatedById=:UserInfo.getUserId()]==0) {
        clientInv = new Client_Inventory__c(CreatedById=currentUser.Id,Name=currentUser.LastName+', '+currentUser.FirstName,Household__c=currentUser.Contact.AccountId);
        insert clientInv;
      } else {
        clientInv = [Select Id From Client_Inventory__c Where CreatedById=:UserInfo.getUserId() Limit 1];
      }
      inventoryId = clientInv.Id;
      PageReference pr = Page.ClientInventory;
      pr.getParameters().put('id',clientInv.Id);
      return pr.setRedirect(true);
      // redirect page to this page
    } else if (UserInfo.getUserType()!='CspLitePortal') {
      ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'This page is editable only by client portal users.'));
    }
    return null;
  }

  public PageReference removeGoalItem() {
    if (itemId!=null && itemId!='') {
      delete [Select Id From Client_Inventory_Item__c Where Id=:itemId];
      queryItemRecords();
      itemId = null;
    } else {
      queryItemRecords();
    }

    return null;
  }  

  // DML METHODS

  // master save method 
  public PageReference saveAllItems() {
    saveItems();
    return null;
  }  

  public PageReference saveAndExit() {
    saveItems();
    return new PageReference(retURL!=null?retURL:'/');
  }    

  public PageReference completeApplication() {
    //insert createQueueTask('Client Inventory');
    //Utility.createQueueTask('Client Inventory',inventoryId,currentUser.Contact.AccountId,currentUser.ContactId,currentUser.FirstName+' '+currentUser.LastName);
    //Utility.sendNotificationEmail('Client Inventory',inventoryId,currentUser.FirstName,currentUser.LastName,currentUser.Portal_Notification_Emails__c);
      Map<String,Boolean> triggerMap = new Map<String,Boolean>{
          'isComplete'=>true
      };
      Utility.sendClientInformationNotification(new Set<Id>{inventoryId},triggerMap,'client_inventory__c');        
    return saveAndExit();    
  }       

  // auto-save to ensure data is not lost here
  public PageReference autoSave() {
    //inventory.AutoSaved__c = System.now();
    upsertDataPoints();
    initialize();

    return null;
  }

  public PageReference updateLastSaved() {
    lastSavedMinutesAgo+=1;
    return null;
  }


  // MASTER SAVE METHOD 
  public PageReference quickSaveItems() {
    // set savepoint for all operations
    SavePoint sp = Database.setSavePoint();
    try {
      upsertDataPoints();
    } catch (Exception e) {
      Database.rollback(sp);
    }

    return null;
  }  

  public PageReference cancelEditInventory() {
    return new PageReference(retURL!=null?retURL:'/');    
  }

  // UPLOADS

  public PageReference upload01() {
    attachmentType = 'Tax Returns';
    return upload();
  }
  public PageReference upload02() {
    attachmentType = 'Bank';
    return upload();
  }
  public PageReference upload03() {
    attachmentType = 'Brokerage';
    return upload();
  }
  public PageReference upload04() {
    attachmentType = 'Insurance';
    return upload();
  }
  public PageReference upload05() {
    attachmentType = 'Pay Stubs';
    return upload();
  }
  public PageReference upload06() {
    attachmentType = 'Retirement';
    return upload();
  }
  public PageReference upload07() {
    attachmentType = 'Estate Planning';
    return upload();
  }
  public PageReference upload08() {
    attachmentType = 'Cost Basis';
    return upload();
  }
  public PageReference upload09() {
    attachmentType = 'Annuity';
    return upload();
  }
  public PageReference upload10() {
    attachmentType = 'Inheritance';
    return upload();
  }
  public PageReference upload11() {
    attachmentType = 'Stock Option';
    return upload();
  }
  public PageReference upload12() {
    attachmentType = 'Partnership';
    return upload();
  }
  public PageReference upload13() {
    attachmentType = 'Business';
    return upload();
  }
  public PageReference upload14() {
    attachmentType = 'Social Security';
    return upload();
  }  
  public PageReference uploadOther() {
    attachmentType = 'Other';
    return upload();
  }  
      
    public PageReference upload() {
    if(attachment.name == null){
      ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Please select a file to upload.'));
          return null;
    }
      if(inventoryId != null){
        attachment.OwnerId = UserInfo.getUserId();
        attachment.ParentId = inventoryId;
        if (attachmentType != 'Other') {
          attachment.Name = attachmentType+' - '+attachment.name;
        }
        try {
          insert attachment;
        } catch (DMLException e) {
          ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error uploading attachment'));
            return null;
        } finally {
          attachment = new Attachment(); 
        }
      }
      queryAttachments();
      return null;
  }


  // INDIVIDUAL ENTRY SAVE METHODS

  // SAVINGS ITEMS


  public PageReference saveSavingsItems() {
    setInventoryIds(savingsItems,inventoryId);
    attemptSave(savingsItems);
    savingsItems = getItemRecords(inventoryId,'Savings');

    return null;
  }  

  public PageReference addSavingsItems() {
    setInventoryIds(savingsItems,inventoryId);
    attemptSave(savingsItems);
    savingsItems.add(new ItemWrapper(new Client_Inventory_Item__c(RecordTypeId=rtIdByName.get('savings'))));

    return null;
  }    

  // INCOME ITEMS


  public PageReference saveIncomeItems() {
    setInventoryIds(incomeItems,inventoryId);
    attemptSave(incomeItems);
    incomeItems = getItemRecords(inventoryId,'Income');

    return null;
  }  

  public PageReference addIncomeItems() {
    setInventoryIds(incomeItems,inventoryId);
    attemptSave(incomeItems);
    incomeItems.add(new ItemWrapper(new Client_Inventory_Item__c(RecordTypeId=rtIdByName.get('income'))));

    return null;
  }  

  // NET WORTH ITEMS

  public PageReference saveNetWorthItems() {
    setInventoryIds(networthItems,inventoryId);
    attemptSave(networthItems);
    networthItems = getItemRecords(inventoryId,'Net Worth');

    return null;
  }  

  public PageReference addNetWorthItems() {
    setInventoryIds(networthItems,inventoryId);
    attemptSave(networthItems);
    networthItems.add(new ItemWrapper(new Client_Inventory_Item__c(RecordTypeId=rtIdByName.get('net worth'))));

    return null;
  }  


  // DEBT (this is the default record type)

  public PageReference saveDebtItems() {
    setInventoryIds(debtItems,inventoryId);
    attemptSave(debtItems);
    debtItems = getItemRecords(inventoryId,'Debt');      

    return null;
  }  

  public PageReference addDebtItems() {
    setInventoryIds(debtItems,inventoryId);
    attemptSave(debtItems);
    debtItems.add(new ItemWrapper(new Client_Inventory_Item__c()));

    return null;
  }

  // CHILDREN AND DEPENDENT ITEMS

  public PageReference saveDependentItems() {
    setInventoryIds(dependentItems,inventoryId);
    attemptSave(dependentItems);
    dependentItems = getItemRecords(inventoryId,'Dependent');    

    return null;
  }      

  public PageReference addDependentItems() {
    setInventoryIds(dependentItems,inventoryId);
    attemptSave(dependentItems);
    dependentItems.add(new ItemWrapper(new Client_Inventory_Item__c(RecordTypeId=rtIdByName.get('dependent'))));

    return null;
  }  

  // generic save items  

  private void attemptSave(List<ItemWrapper> items) {
    Boolean isSuccess = inventoryId!=null;
    try {
      List<Client_Inventory_Item__c> upsertItems = new List<Client_Inventory_Item__c>();
      List<Client_Inventory_Item__c> deleteItems = new List<Client_Inventory_Item__c>();
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

  private List<Client_Inventory_Item__c> setInventoryIds(List<ItemWrapper> items,String invId) {
    List<Client_Inventory_Item__c> newList = new List<Client_Inventory_Item__c>();
    if (invId!=null) {
      for (ItemWrapper i : items) {
        if (!i.RemoveItem) {
          i.item.Client_Inventory__c = invId;
          newList.add(i.item);
        }
      }  
    }
      
    return newList;
  }

  // query for a list of records related to this inventory id if it already exists
  private List<ItemWrapper> getItemRecords(String inventoryId,String recordTypeName) {
    List<ItemWrapper> retList = new List<ItemWrapper>();

    try {
      List<Client_Inventory_Item__c> items = [Select Name,Age__c,Tax_Id__c,Account_Number__c,Type__c,Term_Years__c,Owner__c,Original_Amount__c,Monthly_Payment__c,Interest_Rate__c,
            Description__c,Date__c,Current_Value__c,Cost_Basis__c,Co_Client_Amount__c,Client_Inventory__c,Client_Amount__c,Status__c
          From Client_Inventory_Item__c 
          Where Client_Inventory__c=:inventoryId and RecordType.Name=:recordTypeName];
      for (Client_Inventory_Item__c i : items) {
        retList.add(new ItemWrapper(i));
      }
    } catch (Exception e) {
      System.debug('Error retrieving records '+e.getMessage()+'; '+e.getStackTraceString());
    }

    return retList;
  }

  private void saveItems() {
    // set savepoint for all operations
    SavePoint sp = Database.setSavePoint();
    try {
      upsertDataPoints();
    } catch (Exception e) {
      Database.rollback(sp);
    }    
  }

  private void upsertDataPoints() {
    if (!isReadOnly) {
      // ensure we have an inventory item entry
      inventory.Household__c = currentUser.Contact.AccountId;
      upsert inventory;

      // set inventory id on all items
      upsert setInventoryIds(incomeItems,inventory.Id);    
      upsert setInventoryIds(networthItems,inventory.Id);    
      upsert setInventoryIds(debtItems,inventory.Id);    
      upsert setInventoryIds(dependentItems,inventory.Id);    
      upsert setInventoryIds(savingsItems,inventory.Id);    
      lastSavedMinutesAgo = 0;
    }
  }    

  private void queryItemRecords() {
    // query for related records if the inventory has been created
    incomeItems = getItemRecords(inventoryId,'Income');
    networthItems = getItemRecords(inventoryId,'Net Worth');
    debtItems = getItemRecords(inventoryId,'Debt');      
    dependentItems = getItemRecords(inventoryId,'Dependent');      
    savingsItems = getItemRecords(inventoryId,'Savings');      
  }

  private void queryAttachments() {
    attachments01 = getAttachmentList('Tax Return');
    attachments02 = getAttachmentList('Bank');
    attachments03 = getAttachmentList('Brokerage');
    attachments04 = getAttachmentList('Insurance');
    attachments05 = getAttachmentList('Pay Stubs');
    attachments06 = getAttachmentList('Retirement');
    attachments07 = getAttachmentList('Estate Planning');
    attachments08 = getAttachmentList('Cost Basis');
    attachments09 = getAttachmentList('Annuity');
    attachments10 = getAttachmentList('Inheritance');
    attachments11 = getAttachmentList('Stock Option');
    attachments12 = getAttachmentList('Partnership');
    attachments13 = getAttachmentList('Business');
    attachments14 = getAttachmentList('Social Security');
    allAttachments = getAttachmentList('all');  
    getOtherAttachments();
  }

  private List<Attachment> getAttachmentList(String typeName) {
    try {
      if (isPDF || typeName=='all') {
        return [Select Id,Name,CreatedBy.Name,createddate From Attachment Where ParentId = :inventoryId Order By Name];
      }
      return [Select Id,Name,CreatedBy.Name,createddate From Attachment Where ParentId = :inventoryId and Name like :typeName+'%'];    
    } catch (Exception e) {
      return new List<Attachment>();
    }      
  } 
  
  private void getOtherAttachments() {
    if (inventoryId != null) {
      List<Attachment> all = ClientInventoryHelper.getAttachments(inventoryId);
      this.clientOtherAttachments = new List<Attachment>();
      this.otherAttachments = new List<Attachment>();
      for (Attachment a : all) {
        if (!a.Name.startsWith('Tax Return') && !a.Name.startsWith('Bank') && !a.Name.startsWith('Brokerage') &&
          !a.Name.startsWith('Insurance') && !a.Name.startsWith('Pay Stubs') && !a.Name.startsWith('Retirement') &&
          !a.Name.startsWith('Estate Planning') && !a.Name.startsWith('Cost Basis') && !a.Name.startsWith('Annuity') &&
          !a.Name.startsWith('Inheritance') && !a.Name.startsWith('Stock Option') && !a.Name.startsWith('Partnership') &&
          !a.Name.startsWith('Business') && !a.Name.startsWith('Social Security')) {
            if (a.CreatedBy.Profile.Name == 'CCM Prospect Portal') {
              this.clientOtherAttachments.add(a);
            }
            else {
              this.otherAttachments.add(a);
            }
        } 
      }
      this.otherDocuments = ClientInventoryHelper.getDocuments(inventoryId);
    }
  }

  // NAVIGATION  

  public PageReference priorPage() {
    saveItems();
    if (pageNumber>1) {
      pageNumber--;  
    }

    return null;
  }

  public PageReference nextPage() {
    saveItems();
    if (pageNumber<totalPages) {
      pageNumber++;  
    }
    return null;
  }  

  //public PageReference page0() {
  //  saveItems();
  //  pageNumber = 0;

  //  return null;
  //}      

  public PageReference page1() {
    saveItems();
    pageNumber = 1;

    return null;
  }  

  public PageReference page2() {
    saveItems();
    pageNumber = 2;

    return null;
  }  

  public PageReference page3() {
    saveItems();
    pageNumber = 3;

    return null;
  }  

  public PageReference page4() {
    saveItems();
    pageNumber = 4;

    return null;
  }    

  public PageReference page5() {
    saveItems();
    pageNumber = 5;

    return null;
  }

  public PageReference page6() {
    saveItems();
    pageNumber = 6;

    return null;
  }  

  public PageReference page7() {
    saveItems();
    pageNumber = 7;

    return null;
  }    

  // WRAPPER CLASS

  public class ItemWrapper {
    public Boolean RemoveItem {get;set;}
    public Client_Inventory_Item__c item {get;set;}

    public ItemWrapper(Client_Inventory_Item__c i) {
      this.item = i;
      this.RemoveItem = false;
    }
  }        
}