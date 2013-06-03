component output="false" {

	//DI
	property name="slatwall" inject="id:slatwall";
	property name="slatwallSyncService" inject="id:modules.contentbox.modules.slatwall-coldbox.model.SlatwallSyncService";
	property name="pageService" inject="id:pageService@cb";
	/**
	* Listen to when pages are saved, then call our service to sync the content
	*/
	function cbadmin_postPageSave(event,interceptData) {
		var page = arguments.interceptData.page;
		slatwallSyncService.syncContent(page);
	}


	function cbui_onPageNotFound(event,interceptData) {
		var rc = event.getCollection();
		var prc = event.getCollection(private=true);
		var $ = prc.$;
		var title = '';

		// Setup the correct local in the request object for the current site
		//$.slatwall.setRBLocale( getfwLocale() );  //broken because CB doesn't do this yet fix when locales are ready

		// Inspect the path looking for slatwall URL key, and then setup the proper objects in the slatwallScope
		var brandKeyLocation = 0;
		var productKeyLocation = 0;
		var productTypeKeyLocation = 0;

		// Inspect the rc looking for slatwall URL key, and then setup the proper objects in the slatwallScope
		if (event.valueExists( $.slatwall.setting('globalURLKeyBrand') )) {
			brandKeyLocation = listFindNoCase(event.getCurrentRoutedURL(), $.slatwall.setting('globalURLKeyBrand'), "/");
			title = event.getValue( $.slatwall.setting('globalURLKeyBrand') );
			$.slatwall.setBrand( $.slatwall.getService("brandService").getBrandByURLTitle( title ) );
		}
		if (event.valueExists( $.slatwall.setting('globalURLKeyProduct') )) {
			productKeyLocation = listFindNoCase(event.getCurrentRoutedURL(), $.slatwall.setting('globalURLKeyProduct'), "/");
			title = event.getValue( $.slatwall.setting('globalURLKeyProduct') );
			$.slatwall.setProduct( $.slatwall.getService("productService").getProductByURLTitle( title ) );
		}
		if (event.valueExists( $.slatwall.setting('globalURLKeyProductType') )) {
			productTypeKeyLocation = listFindNoCase(event.getCurrentRoutedURL(), $.slatwall.setting('globalURLKeyProductType'), "/");
			title = event.getValue( $.slatwall.setting('globalURLKeyProductType') );
			$.slatwall.setProductType( $.slatwall.getService("productService").getProductTypeByURLTitle( title ) );
		}
		if(len(title)){

			if( productKeyLocation && productKeyLocation > productTypeKeyLocation && productKeyLocation > brandKeyLocation && !$.slatwall.getCurrentProduct().isNew() && $.slatwall.getCurrentProduct().getActiveFlag() && ($.slatwall.getCurrentProduct().getPublishedFlag() || $.slatwall.getCurrentProduct().setting('productShowDetailWhenNotPublishedFlag'))) {
				$.slatwall.setContent($.slatwall.getService("contentService").getContent($.slatwall.getCurrentProduct().setting('productDisplayTemplate', [$.slatwall.getSite()])));
				var newPage = pageService.get( $.slatwall.getCurrentContent().getCMSContentID() );
				prc.pageOverride = newPage.getSlug();
			}

			controller.runEvent(event=rc.event);
			var mobileDetector = controller.getWireBox().getInstance("mobileDetector@cb");
			var isMobileDevice = mobileDetector.isMobile();
			var thisLayout = ( isMobileDevice ? prc.page.getMobileLayoutWithInheritance() : prc.page.getLayoutWithInheritance() );
			// set skin view
			event.setLayout(name="#prc.cbLayout#/layouts/#thisLayout#", module="contentbox")
			.setView(view="#prc.cbLayout#/views/page", module="contentbox");
		}
	}


}