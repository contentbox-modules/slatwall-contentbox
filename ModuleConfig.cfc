/**
********************************************************************************
ContentBox - A Modular Content Platform
Copyright 2012 by Luis Majano and Ortus Solutions, Corp
www.gocontentbox.org | www.luismajano.com | www.ortussolutions.com
********************************************************************************
Apache License, Version 2.0

Copyright Since [2012] [Luis Majano and Ortus Solutions,Corp]

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
********************************************************************************
*/
component hint="My Module Configuration"{
/**
Module Directives as public properties
this.title 				= "Title of the module";
this.author 			= "Author of the module";
this.webURL 			= "Web URL for docs purposes";
this.description 		= "Module description";
this.version 			= "Module Version"

Optional Properties
this.viewParentLookup   = (true) [boolean] (Optional) // If true, checks for views in the parent first, then it the module.If false, then modules first, then parent.
this.layoutParentLookup = (true) [boolean] (Optional) // If true, checks for layouts in the parent first, then it the module.If false, then modules first, then parent.
this.entryPoint  		= "" (Optional) // If set, this is the default event (ex:forgebox:manager.index) or default route (/forgebox) the framework
									       will use to create an entry link to the module. Similar to a default event.

structures to create for configuration
- parentSettings : struct (will append and override parent)
- settings : struct
- datasources : struct (will append and override parent)
- webservices : struct (will append and override parent)
- interceptorSettings : struct of the following keys ATM
	- customInterceptionPoints : string list of custom interception points
- interceptors : array
- layoutSettings : struct (will allow to define a defaultLayout for the module)
- routes : array Allowed keys are same as the addRoute() method of the SES interceptor.
- wirebox : The wirebox DSL to load and use

Available objects in variable scope
- controller
- appMapping (application mapping)
- moduleMapping (include,cf path)
- modulePath (absolute path)
- log (A pre-configured logBox logger object for this object)
- binder (The wirebox configuration binder)

Required Methods
- configure() : The method ColdBox calls to configure the module.

Optional Methods
- onLoad() 		: If found, it is fired once the module is fully loaded
- onUnload() 	: If found, it is fired once the module is unloaded

*/

	// Module Properties
	this.title 				= "Slatwall Connector";
	this.author 			= "ten24 Web Solutions";
	this.webURL 			= "http://www.getslatwall.com";
	this.description 		= "This is a connector application for Slatwall";
	this.version			= "1.0";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	// Module Entry Point
	this.entryPoint			= "slatwall-connector";

	function configure(){

		// Binder Mappings
		binder.map("slatwall").to("#moduleMapping#.Slatwall.Application").asSingleton();

	}

	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){
		
	}

	function preProcess( required any event, required struct interceptData  ) {
		var slatwall = wireBox.getInstance("slatwall");
		 
		slatwall.setupGlobalRequest();
		
		var prc = event.getCollection(private=true);
		
		if(!structKeyExists(prc, "$")) {
			prc.$ = {};
		}
		prc.$.slatwall = slatwall.getSlatwallScope();
	}
	
	/*
	* Renderer helper injection
	*/
	function afterPluginCreation(event,interceptData){
		
		var prc = event.getCollection(private=true);
		
		
		// check for renderer
		if( isInstanceOf(arguments.interceptData.oPlugin,"coldbox.system.plugins.Renderer") ){
			
			var slatwall = wireBox.getInstance("slatwall");
			
			if(!structKeyExists(arguments.interceptData.oPlugin, "$")) {
				arguments.interceptData.oPlugin.$ = {};	
			}
			
			// decorate it
			arguments.interceptData.oPlugin.$.slatwall = slatwall.getSlatwallScope();
			arguments.interceptData.oPlugin.$slatwallInject = variables.$cbInject;
			arguments.interceptData.oPlugin.$slatwallInject();
			
			// announce event
			announceInterception("cbui_onRendererDecoration",{renderer=arguments.interceptData.oPlugin,CBHelper=arguments.interceptData.oPlugin.cb});
		}
	
	}
	
	/**
	* private inject
	*/
	function $slatwallInject(){
		variables.$ = this.$;
	}

}