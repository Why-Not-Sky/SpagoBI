<%-- SpagoBI, the Open Source Business Intelligence suite

 Copyright (C) 2012 Engineering Ingegneria Informatica S.p.A. - SpagoBI Competency Center
 This Source Code Form is subject to the terms of the Mozilla Public
 License, v. 2.0, without the "Incompatible With Secondary Licenses" notice.  If a copy of the MPL was not distributed with this file,
 You can obtain one at http://mozilla.org/MPL/2.0/. --%>

<%-- 
author: Andrea Gioia (andrea.gioia@eng.it)
--%>
<%@ page language="java" 
	     contentType="text/html; charset=UTF-8" 
	     pageEncoding="UTF-8"%>	


<%-- ---------------------------------------------------------------------- --%>
<%-- JAVA IMPORTS															--%>
<%-- ---------------------------------------------------------------------- --%>
<%@page import="it.eng.spagobi.engines.worksheet.WorksheetEngineInstance"%>
<%@page import="it.eng.spagobi.commons.QbeEngineStaticVariables"%>
<%@page import="it.eng.spagobi.engines.worksheet.bo.WorkSheetDefinition"%>
<%@page import="it.eng.qbe.serialization.serializer.SerializationManager"%>
<%@page import="it.eng.spago.configuration.*"%>
<%@page import="it.eng.qbe.runtime.model.structure.IModelStructure"%>
<%@page import="it.eng.spago.base.*"%>
<%@page import="it.eng.qbe.runtime.datasource.configuration.IDataSourceConfiguration"%>
<%@page import="it.eng.spagobi.engines.qbe.QbeEngineConfig"%>
<%@page import="it.eng.spagobi.engines.qbe.QbeEngineInstance"%>
<%@page import="it.eng.spagobi.utilities.engines.EngineConstants"%>
<%@page import="it.eng.spagobi.commons.bo.UserProfile"%>
<%@page import="it.eng.spago.security.IEngUserProfile"%>
<%@page import="it.eng.spagobi.commons.constants.SpagoBIConstants"%>
<%@page import="java.util.Locale"%>
<%@page import="it.eng.spagobi.services.common.EnginConf"%>
<%@page import="java.util.Map"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Iterator"%>
<%@page import="org.json.JSONObject"%>
<%@page import="it.eng.spagobi.services.proxy.SbiDocumentServiceProxy"%>
<%@page import="it.eng.qbe.serialization.query.serializer.SerializerFactory"%>
<%@page import="it.eng.qbe.runtime.query.Query"%>
<%@page import="org.json.JSONArray"%>
<%-- ---------------------------------------------------------------------- --%>
<%-- JAVA CODE 																--%>
<%-- ---------------------------------------------------------------------- --%>
<%
	QbeEngineInstance qbeEngineInstance;
	WorksheetEngineInstance worksheetEngineInstance;
	QbeEngineConfig qbeEngineConfig;
	WorkSheetDefinition workSheetDefinition;
	UserProfile profile;
	Locale locale;
	String isFromCross;
	boolean isPowerUser;
	Integer resultLimit;
	boolean isMaxResultLimitBlocking;
	boolean isQueryValidationEnabled;
	boolean isQueryValidationBlocking;
	int timeout;
	int crosstabCellLimit;
	int crosstabCalculatedFieldsDecimalePrecison;
	String spagobiServerHost;
	String spagobiContext;
	String spagobiSpagoController;
	
	qbeEngineInstance = (QbeEngineInstance)ResponseContainer.getResponseContainer().getServiceResponse().getAttribute("ENGINE_INSTANCE");
	worksheetEngineInstance = (WorksheetEngineInstance)ResponseContainer.getResponseContainer().getServiceResponse().getAttribute(WorksheetEngineInstance.class.getName());
  	workSheetDefinition = worksheetEngineInstance != null ? 
  			((WorkSheetDefinition) worksheetEngineInstance.getAnalysisState()) 
  			: null;
	profile = (UserProfile)qbeEngineInstance.getEnv().get(EngineConstants.ENV_USER_PROFILE);
	locale = (Locale)qbeEngineInstance.getEnv().get(EngineConstants.ENV_LOCALE);
	
	isFromCross = (String)qbeEngineInstance.getEnv().get("isFromCross");
	if (isFromCross == null) {
		isFromCross = "false";
	}
	isPowerUser = profile.getFunctionalities().contains(SpagoBIConstants.BUILD_QBE_QUERIES_FUNCTIONALITY);
	
	qbeEngineConfig = QbeEngineConfig.getInstance();
    
	
    // settings for max records number limit
    resultLimit = qbeEngineConfig.getResultLimit();
    isMaxResultLimitBlocking = qbeEngineConfig.isMaxResultLimitBlocking();
    isQueryValidationEnabled = qbeEngineConfig.isQueryValidationEnabled();
    isQueryValidationBlocking = qbeEngineConfig.isQueryValidationBlocking();
    timeout = qbeEngineConfig.getQueryExecutionTimeout();
    crosstabCellLimit = qbeEngineConfig.getCrosstabCellLimit();
    crosstabCalculatedFieldsDecimalePrecison = qbeEngineConfig.getCrosstabCFDecimalPrecision();
    spagobiServerHost = request.getParameter(SpagoBIConstants.SBI_HOST);
    spagobiContext = request.getParameter(SpagoBIConstants.SBI_CONTEXT);
    spagobiSpagoController = request.getParameter(SpagoBIConstants.SBI_SPAGO_CONTROLLER);
    
    String jSonPars = "[{}]";
    
    Object documentIdO = qbeEngineInstance.getEnv().get("DOCUMENT_ID");

    if(documentIdO != null) { 
		SbiDocumentServiceProxy proxy = new SbiDocumentServiceProxy(profile.getUserUniqueIdentifier().toString(), session);
		jSonPars = proxy.getDocumentAnalyticalDriversJSON(Integer.valueOf(documentIdO.toString()), locale.getLanguage(), locale.getCountry());
    }
    
%>


<%-- ---------------------------------------------------------------------- --%>
<%-- HTML	 																--%>
<%-- ---------------------------------------------------------------------- --%>

<html>
	
	<head>
		<%@include file="commons/includeExtJS.jspf" %>
		<%@include file="commons/includeMessageResource.jspf" %>
		<%@include file="commons/includeSbiQbeJS.jspf"%>
		
		<%-- START SCRIPT FOR DOMAIN DEFINITION (MUST BE EQUAL BETWEEN SPAGOBI AND EXTERNAL ENGINES) -->
		<script type="text/javascript">
		document.domain='<%= EnginConf.getInstance().getSpagoBiDomain() %>';
		</script>
		<-- END SCRIPT FOR DOMAIN DEFINITION --%>
	
	</head>
	
	<body>
	
    	<script type="text/javascript">  
			Sbi.config = {};
	
			Sbi.config.queryVersion = <%= QbeEngineStaticVariables.CURRENT_QUERY_VERSION %>;
			Sbi.config.worksheetVersion = <%= WorkSheetDefinition.CURRENT_VERSION %>;
			Sbi.config.queryLimit = {};
			Sbi.config.queryLimit.maxRecords = <%= resultLimit != null ? "" + resultLimit.intValue() : "undefined" %>;
			Sbi.config.queryLimit.isBlocking = <%= isMaxResultLimitBlocking %>;
			Sbi.config.queryValidation = {};
			Sbi.config.queryValidation.isEnabled = <%= isQueryValidationEnabled %>;
			Sbi.config.queryValidation.isBlocking = <%= isQueryValidationBlocking %>;
			Sbi.config.queryExecutionTimeout = <%= timeout %>;
			Sbi.config.crosstabCellLimit = <%= crosstabCellLimit %>;
			Sbi.config.crosstabCalculatedFieldsDecimalePrecison = <%= crosstabCalculatedFieldsDecimalePrecison %>;
			
			var url = {
		    	host: '<%= request.getServerName()%>'
		    	, port: '<%= request.getServerPort()%>'
		    	, contextPath: '<%= request.getContextPath().startsWith("/")||request.getContextPath().startsWith("\\")?
		    	   				  request.getContextPath().substring(1):
		    	   				  request.getContextPath()%>'
		    	    
		    };
	
		    var params = {
		    	SBI_EXECUTION_ID: <%= request.getParameter("SBI_EXECUTION_ID")!=null?"'" + request.getParameter("SBI_EXECUTION_ID") +"'": "null" %>
		    };
	
		    Sbi.config.serviceRegistry = new Sbi.service.ServiceRegistry({
		    	baseUrl: url
		        , baseParams: params
		    });
	
			var remoteUrl = {
				completeUrl: '<%= spagobiServerHost + spagobiContext + spagobiSpagoController %>'
			};
		    
		    Sbi.config.remoteServiceRegistry = new Sbi.service.ServiceRegistry({
		    	baseUrl: remoteUrl
		        , baseParams: params
		        , defaultAbsolute: true
		    });
	
	      	var qbeConfig = {};
	      	
	      	<%
	      	JSONArray queries = new JSONArray();
			Iterator queriesIt = qbeEngineInstance.getQueryCatalogue().getAllQueries(false).iterator();
			while (queriesIt.hasNext()) {
				Query query = (Query) queriesIt.next();
				JSONObject queryJSON = (JSONObject) SerializerFactory.getSerializer("application/json").serialize(query, qbeEngineInstance.getDataSource(), locale);
				queries.put(queryJSON);
			}
	      	%>
	      	qbeConfig.initialQueriesCatalogue = {};
	      	qbeConfig.initialQueriesCatalogue.catalogue = {};
	      	qbeConfig.initialQueriesCatalogue.catalogue.queries = <%= queries %>;
	      	qbeConfig.initialQueriesCatalogue.version = Sbi.config.queryVersion;
	      	
	      	qbeConfig.isFromCross = <%= isFromCross %>;
	      	<%
	      	StringBuffer datamartNamesBuffer = new StringBuffer("[");
	      	IModelStructure ms = qbeEngineInstance.getDataSource().getModelStructure();
	      	Iterator<String> it = ms.getModelNames().iterator();
	      	while (it.hasNext()) {
	      		datamartNamesBuffer.append("'" + it.next() + "'");
	      		if (it.hasNext()) {
	      			datamartNamesBuffer.append(",");
	      		}
	      	}
	      	datamartNamesBuffer.append("]");
	      	%>
	      	qbeConfig.westConfig = {};
	      	qbeConfig.westConfig.datamartsName = <%= datamartNamesBuffer.toString() %>;

	      	qbeConfig.externalServicesConfig = <%= qbeEngineInstance.getTemplate() != null ? qbeEngineInstance.getTemplate().getExternalServiceConfigurationsAsJSONArray() : "[]"%>;

	      	qbeConfig.worksheet = {};
	      	qbeConfig.worksheet.engineInitialized = <%= worksheetEngineInstance != null %>;
	      	<%
	      	JSONObject workSheetDefinitionJSON = workSheetDefinition != null ? 
	      			(JSONObject) SerializationManager.serialize(workSheetDefinition, "application/json") : 
	      				new JSONObject();
	      	%>
	      	qbeConfig.worksheet.worksheetTemplate = <%= workSheetDefinitionJSON %>;
	    	
	        // javascript-side user profile object
	        Ext.ns("Sbi.user");
	        Sbi.user.isPowerUser = <%= isPowerUser %>;
	
	        var qbe = null;
	        
	        Ext.onReady(function(){
	        	Ext.QuickTips.init();   
	
		        Ext.ns("Sbi.cache");
		        
	        	
	        	var parametersStore = new Sbi.qbe.DocumentParametersStore({});
	        	var parametersInfo = <%=jSonPars%>;	        	
	        	parametersStore.loadData(parametersInfo);
	        	
	       		qbeConfig.documentParametersStore = parametersStore;

	       		// if user is a power user, instantiate and show also the QueryBuilderPanel
	       		qbeConfig.displayQueryBuilderPanel = Sbi.user.isPowerUser;
	       		qbeConfig.displayFormBuilderPanel = false;
	       		
	           	qbe = new Sbi.qbe.QbePanel(qbeConfig);
	           	var viewport = new Ext.Viewport(qbe);  
	           	<%if (isPowerUser && isFromCross.equalsIgnoreCase("false")) {%>
	           		qbe.queryEditorPanel.selectGridPanel.dropTarget = new Sbi.qbe.SelectGridDropTarget(qbe.queryEditorPanel.selectGridPanel); 
	           		qbe.queryEditorPanel.filterGridPanel.dropTarget = new Sbi.qbe.FilterGridDropTarget(qbe.queryEditorPanel.filterGridPanel);
	           		qbe.queryEditorPanel.havingGridPanel.dropTarget = new Sbi.qbe.HavingGridDropTarget(qbe.queryEditorPanel.havingGridPanel);

	         	<%}%>
	           	
	      	});
	    </script>
	
	</body>

</html>