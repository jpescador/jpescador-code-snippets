public with sharing class CustomReportController {
    private static ReportOutput output = new ReportOutput();

    private class ReportOutput {
        // The data result of our query
        public List<SObject>        result { get; set; }
        // field information containing the api name => label
        public Map<String, String>  columns { get; set; }
        // Used only when a report is created which will
        // contain the report id and name
        public Map<String, String>  info { get; set; }
    }

    // Get the list available of reports
    @RemoteAction
    public static List<Custom_Report__c> getReports() {
        return [select Id, Report_Name__c
                from Custom_Report__c
                order by Report_Name__c];
    }

    // Run the selected report from the dropdown list
    @RemoteAction
    public static ReportOutput runReport(Id reportId) {
        String query = [select Query__c from Custom_Report__c where Id = :reportId].Query__c;
        runQuery(query);

        return output;
    }

    // Validate the query by running it before inserting it. If it was a
    // success then insert it and return the result
    @RemoteAction
    public static ReportOutput createReport(String name, String query) {
        runQuery(query);

        Custom_Report__c report = new Custom_Report__c(
            Report_Name__c = name,
            Query__c = query
        );
        insert report;

        output.info = new Map<String, String>();
        output.info.put('id', report.Id);
        output.info.put('name', report.Report_Name__c);

        return output;
    }

    // Validate the query by running it before updating it. If it was a
    // success then update it and return the result
    @RemoteAction
    public static ReportOutput updateReport(Id reportId, String name, String query) {
        runQuery(query);

        Custom_Report__c report = new Custom_Report__c(
            Id = reportId,
            Report_Name__c = name,
            Query__c = query
        );
        update report;

        return output;
    }

    @RemoteAction
    public static void deleteReport(Id reportId) {
        delete [select Id from Custom_Report__c where Id = :reportId];
    }

    // Get the saved query from the record. This is used when the update report
    // option is selected
    @RemoteAction
    public static String getReportQuery(Id reportId) {
        return [select Query__c from Custom_Report__c where Id = :reportId].Query__c;
    }

    // Set the query text to lowercase, execute the query, and parse the text to
    // retrieve the fields used in the query
    private static void runQuery(String query) {
        String lcQuery = query.toLowerCase();

        output.result = Database.query(lcQuery);
        output.columns = parseQueryFields(lcQuery);
    }

    private static Map<String, String> parseQueryFields(String query) {
        // Get the select fields
        List<String> fields = query.substring(6, query.indexOf('from')).split(',');

        // Get the describe field information of the SObject from the query so that
        // we can save the api name and label that will be used for the column information
        // of our report table
        Map<String, Schema.SObjectField> fieldMap = output.result.getSObjectType().getDescribe().fields.getMap();
        Map<String, String> columnInfo = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult;
        for (String field : fields) {
            // Trim the field from our fields list so that any leading/trailing spaces
            // and carriage returns are not included when getting the field info
            fieldResult = fieldMap.get(field.trim()).getDescribe();
            columnInfo.put(fieldResult.getName(), fieldResult.getLabel());
        }

        return columnInfo;
    }
}
