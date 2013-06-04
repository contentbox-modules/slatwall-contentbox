component output="false" displayname=""  {

	property name="pageService" inject="id:pageService@cb";
	property name="slatwallContentService" inject="entityService:SlatwallContent";
	property name="slatwallSiteService" inject="entityService:SlatwallSite";
	property name="slatwallTypeService" inject="entityService:SlatwallType";
	property name="authorService" 		inject="authorService@cb";
	property name="slatwall" inject="id:slatwall";

	public function init(){
		return this;
	}

	public function setupContent() {
		//get all the currently published pages from contentbox
		var content = getPublishedPages();
		//populate and save Slatwall content with contentbox content
		for (var c in content) {
			var sc = slatwallContentService.new();
			populateAndSaveContent(sc,c);
		}
		//create the slatwall contentbox pages and then create the slatwallContent for them
		createPages();
	}

	public function syncContent(required page, required data) {
		var sc = slatwallContentService.findWhere({cmsContentID=page.getContentID()});
		if(isNull(sc)){
			var sc = slatwallContentService.new();
		}
		if(structKeyExists(data, "productListingPageFlag")) {
			sc.setProductListingPageFlag(true);
		} else {
			sc.setProductListingPageFlag(false);
		}
		if(structKeyExists(data,"contentTemplateType") && len(data.contentTemplateType)) {
			var type = slatwallTypeService.get(data.contentTemplateType);
			sc.setContentTemplateType(type);
		} else {
			//remove the template type
			sc.setContentTemplateType(javaCast('null',''));
		}
		populateAndSaveContent(sc,arguments.page);
	}

	public function removeContent(required page, required data) {
		//manual sql because of hibernate transaction on delete
		var q1 = new Query();
		var sql = "update slatwallcontent set parentContentID = null
					 where contentID in (select sc.contentID from (select contentID from slatwallContent where cmsContentID = :id) as sc );";
		q1.setSQL(sql);
		q1.addParam(name="id",value=page.getContentID());
		q1.execute();
		var q2 = new Query();
		var sql = "delete from slatwallproductlistingpage where contentID in (select contentID from slatwallcontent where cmsContentID = :id);";
		q2.setSQL(sql);
		q2.addParam(name="id",value=page.getContentID());
		q2.execute();
		var q3 = new Query();
		var sql = "delete from slatwallcontent where cmsContentID = :id";
		q3.setSQL(sql);
		q3.addParam(name="id",value=page.getContentID());
		q3.execute();
	}


	private function populateAndSaveContent(slatwallContent,page) {
		//get the site object from slatwall
		var site = getSite();
		arguments.slatwallContent.setCMSContentID(arguments.page.getContentID());
		arguments.slatwallContent.setTitle(arguments.page.getTitle());
		arguments.slatwallContent.setSite(site);
		if(arguments.page.hasParent()){
			var slatwallParent = slatwallContentService.findWhere({cmsContentID=arguments.page.getParent().getContentID()});
			if(isNull(slatwallParent)){
				var slatwallParent = slatwallContentService.new();
				populateAndSaveContent(slatwallParent,arguments.page.getParent());
			}
			arguments.slatwallContent.setParentContent(slatwallParent);
		}
		slatwallContentService.save(arguments.slatwallContent);
	}

	private function setupSite() {
		var site = slatwallSiteService.new();
		site.setSiteName('ContentBox Site');//for now, need to make this more dynamic when we have multi-site capiblities.
		site.setCMSSiteID('1');
		slatwallSiteService.save(site);
		return site;
	}

	private function getSite() {
		var sites = slatwallSiteService.list(max=1,asQuery=false);
		if(!arrayLen(sites)){
			return setupSite();
		}
		return sites[1];
	}

	private function getPublishedPages() {
		var c = pageService.newCriteria();
		// sorting
		var sortOrder = "parent DESC,order";

		// only published pages
		c.isTrue("isPublished")
			.isLT("publishedDate", Now())
			.$or( c.restrictions.isNull("expireDate"), c.restrictions.isGT("expireDate", now() ) )
			// only non-password pages
			.isEq("passwordProtection","");
		var pages 	= c.resultTransformer( c.DISTINCT_ROOT_ENTITY )
							.list(sortOrder=sortOrder,asQuery=false);
		return pages;
	}

	private function createPages() {
		var c = authorService.newCriteria();
		c.createAlias("role","r");
		c.isEq("r.role","Administrator");
		var admins = c.list();
		var author = admins[1];

		//product listing
		var productListingPage = pageService.new();
		productListingPage.setSlug('products');
		productListingPage.setTitle('Products');
		productListingPage.setIsPublished(true);
		productListingPage.setPublishedDate(now());
		productListingPage.setCreator(author);
		productListingPage.setLayout('slatwall-productlisting');
		productListingPage.setCache(false);
		productListingPage.setCacheLayout(false);
		productListingPage.addNewContentVersion(content="", changelog="Initial creation",author=author);
		pageService.savePage( productListingPage, "" );
		var sc = slatwallContentService.new();
		sc.setProductListingPageFlag(true);
		populateAndSaveContent(sc,productListingPage);

		//product
		var productPage = pageService.new();
		productPage.setSlug('product');
		productPage.setTitle('Product');
		productPage.setIsPublished(true);
		productPage.setPublishedDate(now());
		productPage.setCreator(author);
		productPage.setLayout('slatwall-product');
		productPage.setCache(false);
		productPage.setCacheLayout(false);
		productPage.setShowInMenu(false);
		productPage.addNewContentVersion(content="", changelog="Initial creation",author=author);
		pageService.savePage( productPage, "" );
		var sc = slatwallContentService.new();
		var type = slatwallTypeService.findWhere({systemCode='cttProduct'});
		sc.setContentTemplateType(type);
		populateAndSaveContent(sc,productPage);
		//set the slatwall setting to default to this
		var $.slatwall = slatwall.bootstrap();
		var productDisplayTemplateSetting = $.slatwall.getService("settingService").getSettingBySettingName("productDisplayTemplate", true);
		productDisplayTemplateSetting.setSettingValue( sc.getContentID() );
		productDisplayTemplateSetting.setSettingName('productDisplayTemplate');
		productDisplayTemplateSetting.setSite(getSite());
		$.slatwall.getService("settingService").saveSetting( productDisplayTemplateSetting );

		//cart
		var cartPage = pageService.new();
		cartPage.setSlug('cart');
		cartPage.setTitle('Cart');
		cartPage.setIsPublished(true);
		cartPage.setPublishedDate(now());
		cartPage.setCreator(author);
		cartPage.setLayout('slatwall-shoppingcart');
		cartPage.setCache(false);
		cartPage.setCacheLayout(false);
		cartPage.addNewContentVersion(content="", changelog="Initial creation",author=author);
		pageService.savePage( cartPage, "" );
		var sc = slatwallContentService.new();
		populateAndSaveContent(sc,cartPage);

		//account
		var accountPage = pageService.new();
		accountPage.setSlug('acount');
		accountPage.setTitle('Account');
		accountPage.setIsPublished(true);
		accountPage.setPublishedDate(now());
		accountPage.setCreator(author);
		accountPage.setLayout('slatwall-account');
		accountPage.setCache(false);
		accountPage.setCacheLayout(false);
		accountPage.addNewContentVersion(content="", changelog="Initial creation",author=author);
		pageService.savePage( accountPage, "" );
		var sc = slatwallContentService.new();
		populateAndSaveContent(sc,accountPage);

		//checkout
		var checkoutPage = pageService.new();
		checkoutPage.setSlug('checkout');
		checkoutPage.setTitle('Checkout');
		checkoutPage.setIsPublished(true);
		checkoutPage.setPublishedDate(now());
		checkoutPage.setCreator(author);
		checkoutPage.setLayout('slatwall-checkout');
		checkoutPage.setCache(false);
		checkoutPage.setCacheLayout(false);
		checkoutPage.setShowInMenu(false);
		checkoutPage.addNewContentVersion(content="", changelog="Initial creation",author=author);
		pageService.savePage( checkoutPage, "" );
		var sc = slatwallContentService.new();
		populateAndSaveContent(sc,checkoutPage);
	}


}