/**
 * @description       : 
 * @author            : Michael Lloyd (Demand Chain)
 * @group             : 
 * @last modified on  : 10-04-2022
 * @last modified by  : Michael Lloyd (Demand Chain)
**/
public with sharing class NetWorthUtilities {

    /* ON-BALANCE SHEET CATEGORIES/ORDER */ 

    public static String onBalanceSectionMap(String classification) {
        Map<String,String> layoutMap = new Map<String,String>{
                                                'Retirement'=>'RETIREMENT ACCOUNTS',
                                                'Roth'=>'ROTH ACCOUNTS',
                                                'Bank'=>'BANK ACCOUNTS',
                                                'Charitable'=>'CHARITABLE ACCOUNTS',
                                                'Investment'=>'INVESTMENT ACCOUNTS',
                                                'Health Savings' => 'HEALTH SAVINGS ACCOUNTS',
                                                'Qualified Annuity'=>'QUALIFIED ANNUITIES',
                                                'Non-Qualified Annuity'=>'NON-QUALIFIED ANNUITIES',
                                                'Insurance'=>'INSURANCE CASH VALUE',
                                                'Real Estate'=>'REAL ESTATE',
                                                'Education Plan'=>'EDUCATION PLANS',
                                                'Irrevocable Trust'=>'IRREVOCABLE TRUSTS',
                                                'Personal Property/Autos'=>'PERSONAL PROPERTY/AUTOS',
                                                'Notes Receivable'=>'NOTES RECEIVABLE',
                                                'Off-Balance Sheet'=>'OFF-BALANCE SHEET',
                                                'Off Balance Sheet'=>'OFF-BALANCE SHEET',
                                                'Business/Partnerships'=>'BUSINESS/PARTNERSHIPS',
                                                'Liabilities'=>'LIABILITIES',
                                                'Off Balance Liabilities'=>'OFF-BALANCE LIABILITIES'
                                            };

        return layoutMap.get(classification);
    }

    // 1-3 estate, 4 outside estate
    public static Integer estateSections(String classification) {
        Map<String,Integer> layoutMap = new Map<String,Integer>{
                                                'RETIREMENT ACCOUNTS'=>1,
                                                'ROTH ACCOUNTS'=>1,
                                                'BANK ACCOUNTS'=>1,
                                                'INVESTMENT ACCOUNTS'=>1,
                                                'HEALTH SAVINGS ACCOUNTS'=>1,
                                                'QUALIFIED ANNUITIES'=>1,
                                                'NON-QUALIFIED ANNUITIES'=>1,
                                                'INSURANCE CASH VALUE'=>2,
                                                'REAL ESTATE'=>2,
                                                'PERSONAL PROPERTY/AUTOS'=>2,
                                                'NOTES RECEIVABLE'=>2,
                                                'BUSINESS/PARTNERSHIPS'=>3,
                                                'LIABILITIES'=>3,
                                                'OFF-BALANCE SHEET'=>4,
                                                'CHARITABLE ACCOUNTS'=>4,
                                                'IRREVOCABLE TRUSTS'=>4,
                                                'EDUCATION PLANS'=>4,
                                                'INSURANCE DEATH BENEFITS'=>4,
                                                'OFF-BALANCE LIABILITIES'=>4
                                            };

        return layoutMap.get(classification);
    }


    public static List<String> getAllCategoryList() {
        String[] newList = new String[19];
        newList.add(0,'RETIREMENT ACCOUNTS');
        newList.add(1,'ROTH ACCOUNTS');
        newList.add(2,'INVESTMENT ACCOUNTS');
        newList.add(3,'BANK ACCOUNTS');
        newList.add(4,'HEALTH SAVINGS ACCOUNTS');
        newList.add(5,'QUALIFIED ANNUITIES');
        newList.add(6,'NON-QUALIFIED ANNUITIES');
        newList.add(7,'INSURANCE CASH VALUE');
        newList.add(8,'REAL ESTATE');
        newList.add(9,'PERSONAL PROPERTY/AUTOS');
        newList.add(10,'NOTES RECEIVABLE');
        newList.add(11,'BUSINESS/PARTNERSHIPS');
        newList.add(12,'LIABILITIES');
        newList.add(13,'OFF-BALANCE SHEET');
        newList.add(14,'CHARITABLE ACCOUNTS');
        newList.add(15,'IRREVOCABLE TRUSTS');
        newList.add(16,'EDUCATION PLANS');
        newList.add(17,'INSURANCE DEATH BENEFITS');
        newList.add(18,'OFF-BALANCE LIABILITIES');  
        return newList;
    }   

    /* UTILITY METHODS */   

    // per rules from CCM
    public static String categorizeAccount(String type,String custodian) {
        String classification = 'Investment';

        if (custodian!=null && (custodian.toLowerCase().contains('baa-institutional') || custodian.toLowerCase().contains('by all accounts') || custodian.toLowerCase().contains('baa') || custodian.equalsIgnoreCase('tiaa-cref')) ) {
            classification = 'Retirement';
        } else if (type != null) {
            type = type.toLowerCase();
            if (type.contains('roth'))
                classification = 'Roth';        
            else if (type.contains('ira'))
                classification = 'Retirement';
                else if (type.contains('ATRA'))
                classification = 'Retirement';          
            else if (type.contains('joint'))
                classification = 'Investment';  
            else if (type.equalsIgnoreCase('msa deferred comp'))
                classification = 'Retirement';
            else if (type.contains('profit sharing'))
                classification = 'Retirement';
            else if (type == 'RA')
                classification = 'Retirement';
            else if (type.contains('savings account'))
                classification = 'Bank';
            else if (type.contains('cash and munis'))
                classification = 'Bank';
            else if (type.contains('estate account'))
                classification = 'Irrevocable Trust';
            else if (type.contains('estate trust'))
                classification = 'Irrevocable Trust';
            else if (type.contains('exempt gst  share trust'))
                classification = 'Irrevocable Trust';
            else if (type.equalsIgnoreCase('acp charitable gift fund'))
                classification = 'Charitable';          
            else if (type.contains('jackson national life nq'))
                classification = 'Non-Qualified Annuity';
            else if (type.contains('pac life annuity'))
                classification = 'Non-Qualified Annuity';
            else if (type.contains('tiaa - atra'))
                classification = 'Non-Qualified Annuity';
            else if (type.contains('tiaa - atra tpa'))
                classification = 'Non-Qualified Annuity';
            else if (type.contains('tiaa lifetime var select(nq)'))
                classification = 'Non-Qualified Annuity';
            else if (type.contains('tiaa personal annuity'))
                classification = 'Non-Qualified Annuity';
            else if (type.contains('nationwide va'))
                classification = 'Qualified Annuity';
            else if (type.contains('nationwide va crt'))
                classification = 'Qualified Annuity';
            else if (type.contains('john hancock ul'))
                classification = 'Insurance';
            else if (type.contains('note receivable'))
                classification = 'Off-Balance Sheet';
            else if (type.contains('credit shelter trust'))
                classification = 'Irrevocable Trust';
            else if (type.contains('supplemental needs trust'))
                classification = 'Irrevocable Trust';
            else if (type.contains('trust - scottrade'))
                classification = 'Irrevocable Trust';
            else if (type.contains('trust b'))
                classification = 'Irrevocable Trust';
            else if (type.contains('children family trust ii'))
                classification = 'Irrevocable Trust';
            else if (type.contains('mhs charitable remainder trust'))
                classification = 'Charitable';
            else if (type.contains('mhs gift annuity'))
                classification = 'Charitable';
            else if (type.contains('401(k)'))
                classification = 'Retirement';
            else if (type.contains('401k'))
                classification = 'Retirement';
            else if (type.contains('401k-Ind'))
                classification = 'Retirement';
            else if (type.contains('403(b)'))
                classification = 'Retirement';
            else if (type.contains('403b'))
                classification = 'Retirement';      
            else if (type.contains('corporate'))
                classification = 'Business';
            else if (type.contains('partnership'))
                classification = 'Business';
            else if (type.contains('business'))
                classification = 'Business';
            else if (type.contains('margin account'))
                classification = 'Liabilities';
            else if (type.contains('mortgage'))
                classification = 'Liabilities';
            else if (type.contains('offliabilities'))
                classification = 'Off Balance Liabilities';
            else if (type.contains('offliability'))
                classification = 'Off Balance Liabilities';         
            else if (type.contains('liability'))
                classification = 'Liabilities';
            else if (type.contains('liabilities'))
                classification = 'Liabilities';
            else if (type.contains('cdbank'))
                classification = 'Investment';
            else if (type.contains('living trust'))
                classification = 'Investment';
            else if (type.contains('checking'))
                classification = 'Bank';
            else if (type.contains('bank'))
                classification = 'Bank';
            else if (type.contains('real estate'))
                classification = 'Real Estate';
            else if (type.contains('ilit'))
                classification = 'Off-Balance Sheet';
            else if (type.contains('non?q'))
                classification = 'Non-Qualified Annuity';
            else if (type.contains('nonq'))
                classification = 'Non-Qualified Annuity';
            else if (type.contains('variable annuity'))
                classification = 'Non-Qualified Annuity';
            else if (type.contains('non?qualifiedannuity'))
                classification = 'Non-Qualified Annuity';
            else if (type.contains('annuitynon?qualified'))
                classification = 'Non-Qualified Annuity';
            else if (type.contains('vanguard annuity'))
                classification = 'Qualified Annuity';
            else if (type.contains('lincoln benefit'))
                classification = 'Qualified Annuity';
            else if (type.contains('annuity'))
                classification = 'Qualified Annuity';
            else if (type.contains('annuities'))
                classification = 'Qualified Annuity';
            else if (type.contains('variable life'))
                classification = 'Insurance';
            else if (type.contains('universal life'))
                classification = 'Insurance';
            else if (type.contains('insurance'))
                classification = 'Insurance';
            else if (type.contains('charitable remainder trust'))
                classification = 'Irrevocable Trust';
            else if (type.contains('crt'))
                classification = 'Irrevocable Trust';
            else if (type.contains('ctc'))
                classification = 'Irrevocable Trust';
            else if (type.contains('generation skipping'))
                classification = 'Irrevocable Trust';
            else if (type.contains('gst'))
                classification = 'Irrevocable Trust';
            else if (type.contains('irrev'))
                classification = 'Irrevocable Trust';
            else if (type.contains('529'))
                classification = 'Education Plan';
            else if (type.contains('education'))
                classification = 'Education Plan';
            else if (type.contains('acp'))
                classification = 'Charitable';
            else if (type.contains('daf'))
                classification = 'Charitable';
            else if (type.contains('donar advised'))
                classification = 'Charitable';
            else if (type.contains('non-profit'))
                classification = 'Charitable';
            else if (type.contains('charity'))
                classification = 'Charitable';
            else if (type.contains('charitable'))
                classification = 'Charitable';
            else if (type.contains('taxable'))
                classification = 'Investment';
            else if (type.contains('investment'))
                classification = 'Investment';
            else if (type.contains('death'))
                classification = 'Insurance Death Benefits';
            else if (type.contains('property'))
                classification = 'Personal Property/Autos';
            else if (type.contains('auto'))
                classification = 'Personal Property/Autos';
            else if (type.contains('car'))
                classification = 'Personal Property/Autos';
            else if (type.contains('vehicle'))
                classification = 'Personal Property/Autos';
            else if (type.contains('off?balance'))
                classification = 'Off-Balance Sheet';
            else if (type.contains('TIAA - RHA'))
                classification = 'Health Savings';
        }

        return classification;
    }

    //// on-balance sheet 
    //public static Integer onSortOrderMap(String headingName) {
    //  Map<String,Integer> sortMap = new Map<String,Integer>{
    //                                          'RETIREMENT ACCOUNTS'=>0,
    //                                          'ROTH ACCOUNTS'=>1,
    //                                          'BANK ACCOUNTS'=>2,
    //                                          'INVESTMENT ACCOUNTS'=>3,
    //                                          'QUALIFIED ANNUITIES'=>4,
    //                                          'NON-QUALIFIED ANNUITIES'=>5,
    //                                          'INSURANCE CASH VALUE'=>6,
    //                                          'REAL ESTATE'=>7,
    //                                          'PERSONAL PROPERTY/AUTOS'=>8,
    //                                          'NOTES RECEIVABLE'=>9,
    //                                          'BUSINESS/PARTNERSHIPS'=>10,
    //                                          'LIABILITIES'=>11
    //                                      };
    //  return sortMap.get(headingName);
    //} 

    ///* OFF-BALANCE SHEET CATEGORIES/ORDER */ 

    //public static String offBalanceSectionMap(String classification) {
    //  Map<String,String> layoutMap = new Map<String,String>{
    //                                          'Off Balance Sheet'=>'OFF-BALANCE SHEET',
    //                                          'Charitable'=>'CHARITABLE ACCOUNTS',
    //                                          'Irrevocable Trust'=>'IRREVOCABLE TRUSTS',
    //                                          'Education Plan'=>'EDUCATION PLANS',
    //                                          'Insurance'=>'INSURANCE DEATH BENEFITS',
    //                                          'Off Balance Liabilities'=>'OFF-BALANCE LIABILITIES'
    //                                      };

    //  return layoutMap.get(classification);
    //}

    //public static Integer offSortOrderMap(String headingName) {
    //  Map<String,Integer> sortMap = new Map<String,Integer>{
    //                                          'OFF-BALANCE SHEET'=>0,
    //                                          'CHARITABLE ACCOUNTS'=>1,
    //                                          'IRREVOCABLE TRUSTS'=>2,
    //                                          'EDUCATION PLANS'=>3,
    //                                          'INSURANCE DEATH BENEFITS'=>4,
    //                                          'OFF-BALANCE LIABILITIES'=>5
    //                                      };
    //  return sortMap.get(headingName);
    //}

    //public static Map<Integer,String> getAllCategories() {
    //  return new Map<Integer,String>{
    //                                          0=>'RETIREMENT ACCOUNTS',
    //                                          1=>'ROTH ACCOUNTS',
    //                                          2=>'BANK ACCOUNTS',
    //                                          3=>'INVESTMENT ACCOUNTS',
    //                                          4=>'QUALIFIED ANNUITIES',
    //                                          5=>'NON-QUALIFIED ANNUITIES',
    //                                          6=>'INSURANCE CASH VALUE',
    //                                          7=>'REAL ESTATE',
    //                                          8=>'PERSONAL PROPERTY/AUTOS',
    //                                          9=>'NOTES RECEIVABLE',
    //                                          10=>'BUSINESS/PARTNERSHIPS',
    //                                          11=>'LIABILITIES',
    //                                          12=>'OFF-BALANCE SHEET',
    //                                          13=>'CHARITABLE ACCOUNTS',
    //                                          14=>'IRREVOCABLE TRUSTS',
    //                                          15=>'EDUCATION PLANS',
    //                                          16=>'INSURANCE DEATH BENEFITS',
    //                                          17=>'OFF-BALANCE LIABILITIES'                                   
    //                                      };
    //}

}