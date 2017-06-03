/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class test_helpme {

    static testMethod void myUnitTest() {
        Pagereference pageref=page.partknowledge;
        Test.setCurrentPage(pageRef);
        Account act = new Account (name= 'testacct');
        insert act;
        Contact cct = new Contact (lastname = 'testest', accountid= act.id);
        insert cct;
        Asset ast= new Asset(name = 'zyx', product_type__c='abcdef', description='hgijkl',accountid = act.id, contactid = cct.id);
        insert ast;
        string assid = [select id from Asset where product_type__c='abcdef'].id;
        ApexPages.currentPage().getParameters().put('def_asset_id', ast.id);
        helpme controller = new helpme(); 
        string s = 'hgijkl';
        controller.setSrch(s);
        controller.getSrch()      ; 
        string nextp = controller.dosearch().geturl();
        System.assertEquals('/apex/partresults',nextp);
        Asset ass1 = controller.getTheasset();
        System.assertEquals('abcdef',ass1.Product_Type__c);
        controller.getMylist();
    }
}