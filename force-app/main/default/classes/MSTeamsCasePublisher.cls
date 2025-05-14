public class MSTeamsCasePublisher {
   private static final String newCaseURL = 'https://outlook.office.com/webhook/d1712452-d697-45dc-9cc7-35423bdc3f89@c26eb5b5-c761-47c1-8678-d2b9bd324954/IncomingWebhook/91d2effdc6fa4196b7c3bae1347ee51c/8ca860b1-9fb7-479b-a1e9-e314bec3c0f2';
   @testvisible    
   public class SFCase {
       //pass the entire case sObject through process builder
       @InvocableVariable(label='Case')
       public Case myCase;              
       //pass the entire contact sObject through process builder
       @InvocableVariable(label='Contact')
       public Contact caseContact;
       //pass a new flag
       @InvocableVariable(label='IsNew')
       public boolean isNew;
       
       public SFCase() {}
       
       public SFCase(Case c, Contact con, boolean isn){          
           this.myCase = c;
           this.caseContact = con;           
           this.isNew = isn;
       }
   }
   
    public class MSTeamsMessage{
        public string type = 'MessageCard';
        public string context = 'http://schema.org/extensions';   
        public string themeColor = 'ffd517';
        public string summary = 'summary';
        public List<Section> sections {get; private set;}
        public MSTeamsMessage(){
            sections = new List<section>();
        }
    }
    
    public class Section {
        public string title {get;set;}
        public List<Fact> facts {get;private set;}
        public Section(string t){
            title = t;
            facts = new List<Fact>();
        }
    }
    
    public class Fact {
        public string name {get;set;}
        public string value {get;set;}
        
        public Fact(string n, string v){
            name = n;
            value = v;
        }
    }
   
   @InvocableMethod(label='Post to MS Teams')
   public static void postToTeams(List<SFCase> cases) {
       SFCase c = cases[0]; // If bulk, only post first to avoid overloading MS Teams channel
       List<User> ownerUser = [select Id, FirstName, LastName, Microsoft_Teams_Call_Back_URL__c from User where id=:c.myCase.OwnerId limit 1];
       List<Group> ownerQueue = [select Id, Name from Group where id=:c.myCase.OwnerId limit 1];
       
       string ownerId = c.myCase.OwnerId;
       string ownerType = '';
       string ownerName = '';
       string urlNew = newCaseURL;
       string url = '';
       
       if(ownerId.left(3)=='005'){ 
           ownerName = ownerUser[0].FirstName + ' ' + ownerUser[0].LastName; 
           ownerType='User'; 
           ownerId=ownerUser[0].Id; 
           url = ownerUser[0].Microsoft_Teams_Call_Back_URL__c; 
       } else { 
           ownerName = ownerQueue[0].Name; 
           ownerType='Queue'; 
           ownerId=ownerQueue[0].Id; 
       }
       
       if(ownerType=='User' && url != ''){
       
       //post assigned cases to specific channels
       MSTeamsMessage msg = new MSTeamsMessage();       
       Section s = new Section('Case ' + c.myCase.CaseNumber + ' has been assigned to ' + ownerName);
       msg.sections.add(s);
       Fact fLink= new Fact('Link:', '[View in FSC](https://ccmfsc.lightning.force.com/lightning/r/Case/' + c.myCase.Id + '/view)');
       s.facts.add(fLink);
       Fact fSubject = new Fact('Subject:', c.myCase.Subject);
       s.facts.add(fSubject);
       Fact fFrom= new Fact('From:', c.caseContact.FirstName + ' ' + c.caseContact.LastName);
       s.facts.add(fFrom);
       Fact fDescription = new Fact('Description:', c.myCase.Description);
       s.facts.add(fDescription);
           
       String body = JSON.serialize(msg);

       System.enqueueJob(new QueueableMSTeamsCall(url, 'POST', body));
       
       }

   }
   
   public class QueueableMSTeamsCall implements System.Queueable, Database.AllowsCallouts {
        
       private final String url;
       private final String method;
       private final String body;
        
       public QueueableMSTeamsCall(String url, String method, String body) {
           this.url = url;
           this.method = method;
           this.body = body;
       }
        
       public void execute(System.QueueableContext ctx) {
           HttpRequest req = new HttpRequest();
           req.setEndpoint(url);
           req.setMethod(method);
           req.setBody(body);
           Http http = new Http();
           HttpResponse res = http.send(req);
       }
    }
}