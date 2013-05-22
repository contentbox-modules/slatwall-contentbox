component output="false" displayname=""  {

	property name="pageService" inject="id:pageService@cb";
	property name="slatwallContentService" inject="entityService:SlatwallContent";
	property name="slatwallSiteService" inject="entityService:SlatwallSite";

	public function init(){
		return this;
	}

	public function setupContent() {
		//get all the currently published pages from contentbox
		var content = pageService.findPublishedPages();
		//populate and save Slatwall content with contentbox content
		for (var c in content.pages) {
			var sc = slatwallContentService.new();
			populateAndSaveContent(sc,c);
			//TODO: parent/child content relationship
		}
	}

	public function syncContent(page) {
		var sc = slatwallContentService.findWhere({cmsContentID=page.getContentID()});
		if(isNull(sc)){
			var sc = slatwallContentService.new();
		}
		populateAndSaveContent(sc,arguments.page);
	}

	private function populateAndSaveContent(slatwallContent,page) {
		//get the site object from slatwall
		var site = getSite();
		arguments.slatwallContent.setCMSContentID(arguments.page.getContentID());
		arguments.slatwallContent.setTitle(arguments.page.getTitle());
		arguments.slatwallContent.setSite(site);
		slatwallContentService.save(arguments.slatwallContent);
	}

	private function setupSite() {
		var site = slatwallSiteService.new();
		site.setSiteName('ContentBox Site');//for now, need to make this more dynamic when we have multi-site capiblities.
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


}