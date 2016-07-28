component hint="My Module Configuration"{

	// Module Properties
	this.title 				= "Slatwall Connector";
	this.author 			= "ten24 Web Solutions";
	this.webURL 			= "http://www.getslatwall.com";
	this.description 		= "This is a connector application for Slatwall";
	this.version			= "2.0.0";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	// Module Entry Point
	this.entryPoint			= "slatwall-coldbox";

	this.slatwallInstalled	= false;
	this.slatwallConfigured	= false;
	this.slatwall 			= "";

	function configure(){
	}

	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){
		if(not getSlatwallInstalledFlag()) {

			var appMeta = getAppMeta();
			if(isStruct(appMeta.datasource) && structKeyExists(appMeta.datasource, "name")) {
				var ds = appMeta.datasource.name;
			} else {
				var ds = appMeta.datasource;
			}
			//get the ContentBox Layout service
			var ThemeService = wirebox.getInstance('ThemeService@cb');
			var layoutPath = '';
			//if we are in ContentBox, this won't be null, so now we know
			if (!isNull(ThemeService)) {
				var theme = ThemeService.getActiveTheme();
				layoutPath = "#theme.directory#/#theme.name#/";
			}
			var slatwallSetup = new models.SlatwallSetup();
			slatwallSetup.setupSlatwall(appPath=expandPath('/'), applicationName=appMeta.name, applicationDatasource=ds, layoutPath=layoutPath);

		}

		//If slatwall is installed, do some extra stuff
		if(getSlatwallInstalledFlag()) {
			binder.map("slatwall").toValue(new Slatwall.Application()).asSingleton();
			//setup the wirebox mapping and bootstrap
			var slatwall = wirebox.getInstance("slatwall");
			slatwall.bootstrap();
			// register the interceptor to listen to all events declared
			controller.getInterceptorService()
				.registerInterceptor(interceptorClass="#moduleMapping#.interceptors.slatwall");
		}

		// ContentBox loaded?
		if( structKeyExists( controller.getSetting("modules"), "contentbox" ) ){
			// Let's add ourselves to the main menu in the Modules section
			var menuService = wirebox.getInstance("AdminMenuService@cb");
			// Add Menu Contribution
			menuService.addSubMenu(topMenu=menuService.MODULES,name="Slatwall",label="Slatwall Admin",href="#appMapping#/Slatwall");
		}
	}

		/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){
		// ContentBox unloading
		if( structKeyExists( controller.getSetting("modules"), "contentbox" ) ){
			// Let's remove ourselves to the main menu in the Modules section
			var menuService = wirebox.getInstance("AdminMenuService@cb");
			// Remove Menu Contribution
			menuService.removeSubMenu(topMenu=menuService.MODULES,name="Slatwall");
		}
	}

	/**
	* Fired when the module is activated by ContentBox Only
	*/
	function onActivate(){
		//If we haven't synced up the content yet, do it!
		if(not getSlatwallContentConfigured()) {
			var prc = controller.getRequestService().getContext().getCollection(private=true);
			var slatwallSyncService = wirebox.getInstance("modules.contentbox.modules.slatwall-coldbox.models.SlatwallSyncService");
			slatwallSyncService.setupContent(prc.oAuthor);
		}
	}

	function preProcess( required any event, required struct interceptData  ) {
		if(getSlatwallConfiguredFlag() && getSlatwallInstalledFlag()) {

			var slatwall = wirebox.getInstance("slatwall");

			var prc = event.getCollection(private=true);
			var rc = event.getCollection();

			if(!structKeyExists(prc, "$")) {
				prc.$ = {};
			}

			prc.$.slatwall = slatwall.bootstrap();
			prc.$.slatwall.setSite( prc.$.slatwall.getService('siteService').getSiteByCMSSiteID( '1' ) ); //set dynamicly when we are multitenant
			if(structKeyExists(prc,"page")){
				prc.$.slatwall.setContent( $.slatwall.getService("contentService").getContentByCMSContentID(prc.page.getContentID()) );
			}

			if(event.valueExists( name="slatAction")) {

				var actionArray = listToArray( rc.slatAction );

				for(var a=1; a<=arrayLen(actionArray); a++) {
					prc.$.slatwall.doAction( actionArray[a], rc );
				}
			}
		}
	}

	/*
	* Renderer helper injection
	*/
	function afterInstanceCreation(event,interceptData){

		if(getSlatwallConfiguredFlag() && getSlatwallInstalledFlag()) {
			var prc = event.getCollection(private=true);

			// check for renderer
			if( isInstanceOf(arguments.interceptData.target,"coldbox.system.web.Renderer") ){
				var slatwall = wirebox.getInstance("slatwall");

				if(!structKeyExists(arguments.interceptData.target, "$")) {
					arguments.interceptData.target.$ = {};
				}

				// decorate it
				arguments.interceptData.target.$.slatwall = request.slatwallScope;
				arguments.interceptData.target.$slatwallInject = variables.$slatwallInject;
				arguments.interceptData.target.$slatwallInject();

			}
		}

	}

	/**
	* private inject
	*/
	function $slatwallInject(){
		variables.$ = this.$;
	}

	private struct function getAppMeta() {
		if( listFirst(server.coldfusion.productVersion,",") gte 10 ){
			return getApplicationMetadata();
		} else{
			return application.getApplicationSettings();
		}
	}

	private boolean function getSlatwallInstalledFlag() {
		if(this.slatwallInstalled) {
			return true;
		}

		this.slatwallInstalled = directoryExists(expandPath('/Slatwall'));

		return this.slatwallInstalled;
	}

	private boolean function getSlatwallConfiguredFlag() {
		if(this.slatwallConfigured) {
			return true;
		}
		var appMeta = getAppMeta();

		this.slatwallConfigured = structKeyExists(appMeta.Mappings, "/Slatwall") && structKeyExists(appMeta, "ormEnabled") && appMeta.ormEnabled && structKeyExists(appMeta, "datasource");

		return this.slatwallConfigured;
	}

	private boolean function getSlatwallContentConfigured() {
		var slatwall = wirebox.getInstance("slatwall");
		slatwall.bootstrap();
		var content = entityLoad('SlatwallContent',{},{maxResults=1});
		return arrayLen(content);
	}

}