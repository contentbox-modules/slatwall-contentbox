<cfcomponent output="false">

	<cfproperty name="appPath" inject="coldbox:setting:applicationPath" />

	<cffunction name="setupSlatwall">
		<cfargument name="appPath" type="string" required="true">
		<cfargument name="applicationName" type="string" required="true">
		<cfargument name="applicationDatasource" type="string" required="true">


		<!--- Define what the Slatwall directory will be --->
		<cfset var slatwallDirectoryPath = "#arguments.appPath#/Slatwall" />

		<!--- Verify that Slatwall isn't installed --->
		<cfif not directoryExists(slatwallDirectoryPath)>

			<!--- start download --->
			<cfhttp url="https://github.com/ten24/Slatwall/archive/rc3.zip" method="get" path="#getTempDirectory()#" file="slatwall.zip" />

			<!--- Unzip downloaded file --->
			<cfset var slatwallZipDirectoryList = "" />
			<cfzip action="unzip" destination="#arguments.appPath#" file="#getTempDirectory()#slatwall.zip" >
			<cfdirectory action="rename" directory="#arguments.appPath#/Slatwall-rc3" newdirectory="#arguments.appPath#/Slatwall" />
			<!--- Set Application Datasource in custom Slatwall config --->
			<cffile action="write" file="#slatwallDirectoryPath#/custom/config/configApplication.cfm" output='<cfset this.name = "#arguments.applicationName#" />#chr(13)#<cfset this.datasource.name = "#arguments.applicationDatasource#" />'>
			<cffile action="write" file="#slatwallDirectoryPath#/custom/config/configORM.cfm" output='<cfset this.ormsettings.cfclocation=["../model","../modules","/Slatwall/model/entity"] />'>
			<cfset processAppCFCUpdate(appPath) />
			<cfset applicationStop() />
			<!--- CF9 stupid cached dsn --->
			<cfif( listFirst( server.coldfusion.productVersion ) eq 9 )>
				<cfinclude template="../views/cf9-refresher.cfm" />
				<cfabort />
			</cfif>
		</cfif>
	</cffunction>

	<cfscript>
		function processAppCFCUpdate(appPath){
			var appCFCPath = arguments.appPath & "Application.cfc";
			var c = fileRead(appCFCPath);
			var start = len(c)-1;
			c = insert('#chr(13)#//Slatwall Setup#chr(13)#this.mappings["/Slatwall"] = COLDBOX_APP_ROOT_PATH & "Slatwall";#chr(13)#arrayAppend(this.ormSettings.cfclocation,"/Slatwall/model/entity");#chr(13)#', c, start);
			fileWrite(appCFCPath, c);
		}
	</cfscript>

</cfcomponent>