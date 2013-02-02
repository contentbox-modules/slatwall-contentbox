<cfcomponent output="false">
	
	<cffunction name="setupSlatwall">
		<cfargument name="moduleDirectoryPath" type="string" required="true">
		<cfargument name="applicationName" type="string" required="true">
		<cfargument name="applicationDatasource" type="string" required="true">
		
		
		<!--- Define what the Slatwall directory will be ---> 
		<cfset var slatwallDirectoryPath = "#getDirectoryFromPath(expandPath('/'))#Slatwall" />
		
		<!--- Verify that Slatwall isn't installed --->
		<cfif not directoryExists(slatwallDirectoryPath)>
			
			<!--- start download --->
			<cfhttp url="https://github.com/ten24/Slatwall/archive/feature-standalone.zip" method="get" path="#getTempDirectory()#" file="slatwall.zip" />
			
			<!--- Unzip downloaded file --->
			<cfset var slatwallZipDirectoryList = "" />
			<cfzip action="unzip" destination="#getTempDirectory()#" file="#getTempDirectory()#slatwall.zip" >
			<cfzip action="list" file="#getTempDirectory()#slatwall.zip" name="slatwallZipDirectoryList" >
			
			<!--- Move the directory from where it is in the temp location to this directory --->
			<cfdirectory action="rename" directory="#getTempDirectory()##listFirst(listFirst(slatwallZipDirectoryList.DIRECTORY, "\"), "/")#/" newdirectory="#slatwallDirectoryPath#" />
			
			<!--- Set Application Datasource in custom Slatwall config --->
			<cffile action="write" file="#slatwallDirectoryPath#/custom/config/configApplication.cfm" output='<cfset this.datasource.name = "#arguments.applicationDatasource#" />#chr(13)#<cfset this.name = "#arguments.applicationName#" />'>
			
		</cfif>
	</cffunction>
	
</cfcomponent>