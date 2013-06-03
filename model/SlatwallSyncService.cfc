component output="false" displayname=""  {

	property name="pageService" inject="id:pageService@cb";
	property name="slatwallContentService" inject="entityService:SlatwallContent";
	property name="slatwallSiteService" inject="entityService:SlatwallSite";

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
		populateAndSaveContent(sc,arguments.page);
	}

	private function populateAndSaveContent(slatwallContent,page) {
		//get the site object from slatwall
		var site = getSite();
		arguments.slatwallContent.setCMSContentID(arguments.page.getContentID());
		arguments.slatwallContent.setTitle(arguments.page.getTitle());
		arguments.slatwallContent.setSite(site);
		if(arguments.page.hasParent()){
			var slatwallParent = slatwallContentService.findWhere({cmsContentID=arguments.page.getParent().getContentID()});
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
		var sortOrder = "parent,order";

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


}